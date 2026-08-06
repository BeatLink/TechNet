#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#define PAGEMAP_PRESENT (1ULL << 63)
#define PAGEMAP_SWAPPED (1ULL << 62)
#define PAGEMAP_CHUNK   1024

static size_t page_size;

struct range {
        char     *path;
        uint64_t  off;
        uint64_t  len;
};

static void
emit (const char *path, uint64_t off, uint64_t len, uint64_t fsize)
{
        if (len == 0 || off >= fsize)
                return;
        if (off + len > fsize)
                len = fsize - off;

        printf ("%s\t%" PRIu64 "\t%" PRIu64 "\n", path, off, len);
}

static void
record_pid (const char *pid, uint64_t min_size, const char *prefix)
{
        char  path[128];
        FILE *maps;
        int   pagemap;
        char *line = NULL;
        size_t cap = 0;

        snprintf (path, sizeof path, "/proc/%s/maps", pid);
        maps = fopen (path, "r");
        if (maps == NULL) {
                fprintf (stderr, "preload-pages: %s: %s\n", path, strerror (errno));
                return;
        }

        snprintf (path, sizeof path, "/proc/%s/pagemap", pid);
        pagemap = open (path, O_RDONLY);
        if (pagemap < 0) {
                fprintf (stderr, "preload-pages: %s: %s\n", path, strerror (errno));
                fclose (maps);
                return;
        }

        while (getline (&line, &cap, maps) > 0) {
                uint64_t      start, end, pgoff;
                unsigned long inode;
                char          perms[8];
                int           at = 0;
                char         *file, *nl;
                struct stat   st;
                uint64_t      npages, run_off = 0, run_len = 0, i;
                uint64_t      buf[PAGEMAP_CHUNK];

                if (sscanf (line, "%" SCNx64 "-%" SCNx64 " %7s %" SCNx64 " %*x:%*x %lu %n",
                            &start, &end, perms, &pgoff, &inode, &at) < 5)
                        continue;

                if (inode == 0 || at <= 0 || perms[0] != 'r')
                        continue;

                file = line + at;
                while (*file == ' ')
                        file++;
                nl = strchr (file, '\n');
                if (nl != NULL)
                        *nl = '\0';

                if (*file != '/' || strstr (file, "(deleted)") != NULL)
                        continue;
                if (prefix != NULL && strncmp (file, prefix, strlen (prefix)) != 0)
                        continue;
                if (stat (file, &st) != 0 || !S_ISREG (st.st_mode))
                        continue;
                if ((uint64_t) st.st_size < min_size)
                        continue;

                npages = (end - start) / page_size;

                for (i = 0; i < npages; ) {
                        uint64_t n = npages - i;
                        ssize_t  got;
                        uint64_t k;

                        if (n > PAGEMAP_CHUNK)
                                n = PAGEMAP_CHUNK;

                        got = pread (pagemap, buf, n * sizeof buf[0],
                                     (off_t) ((start / page_size + i) * sizeof buf[0]));
                        if (got <= 0)
                                break;

                        n = (uint64_t) got / sizeof buf[0];

                        for (k = 0; k < n; k++) {
                                uint64_t foff;

                                if ((buf[k] & (PAGEMAP_PRESENT | PAGEMAP_SWAPPED)) == 0)
                                        continue;

                                foff = pgoff + (i + k) * page_size;

                                if (run_len != 0 && run_off + run_len == foff) {
                                        run_len += page_size;
                                } else {
                                        emit (file, run_off, run_len, st.st_size);
                                        run_off = foff;
                                        run_len = page_size;
                                }
                        }

                        i += n;
                }

                emit (file, run_off, run_len, st.st_size);
        }

        free (line);
        close (pagemap);
        fclose (maps);
}

static int
cmp_range (const void *a, const void *b)
{
        const struct range *ra = a, *rb = b;
        int cmp = strcmp (ra->path, rb->path);

        if (cmp != 0)
                return cmp;
        if (ra->off < rb->off)
                return -1;
        return ra->off > rb->off;
}

static int
read_profile (FILE *in, struct range **out, size_t *n, size_t *cap)
{
        char  *line = NULL;
        size_t lcap = 0;

        while (getline (&line, &lcap, in) > 0) {
                char *tab1, *tab2, *nl;

                nl = strchr (line, '\n');
                if (nl != NULL)
                        *nl = '\0';

                tab1 = strchr (line, '\t');
                if (tab1 == NULL)
                        continue;
                tab2 = strchr (tab1 + 1, '\t');
                if (tab2 == NULL)
                        continue;

                *tab1 = '\0';
                *tab2 = '\0';

                if (*n == *cap) {
                        *cap = *cap ? *cap * 2 : 256;
                        *out = realloc (*out, *cap * sizeof **out);
                        if (*out == NULL)
                                return -1;
                }

                (*out)[*n].path = strdup (line);
                (*out)[*n].off  = strtoull (tab1 + 1, NULL, 10);
                (*out)[*n].len  = strtoull (tab2 + 1, NULL, 10);

                if ((*out)[*n].path == NULL)
                        return -1;
                if ((*out)[*n].len != 0)
                        (*n)++;
        }

        free (line);
        return 0;
}

static int
lock_ranges (char **profiles, int nprofiles, uint64_t max_total)
{
        struct range *r = NULL;
        size_t n = 0, cap = 0, i;
        uint64_t locked = 0, skipped = 0;
        unsigned mapped = 0, failed = 0;
        char *open_path = NULL;
        int fd = -1;

        if (nprofiles == 0) {
                if (read_profile (stdin, &r, &n, &cap) != 0)
                        return 1;
        } else {
                for (i = 0; i < (size_t) nprofiles; i++) {
                        FILE *in = fopen (profiles[i], "r");

                        if (in == NULL) {
                                fprintf (stderr, "preload-pages: %s: %s\n",
                                         profiles[i], strerror (errno));
                                continue;
                        }
                        if (read_profile (in, &r, &n, &cap) != 0) {
                                fclose (in);
                                return 1;
                        }
                        fclose (in);
                }
        }

        if (n == 0) {
                fprintf (stderr, "preload-pages: nothing to lock\n");
                return 0;
        }

        qsort (r, n, sizeof *r, cmp_range);

        for (i = 0; i < n; i++) {
                uint64_t off = r[i].off, end = r[i].off + r[i].len;
                void    *addr;

                while (i + 1 < n && strcmp (r[i + 1].path, r[i].path) == 0 &&
                       r[i + 1].off <= end) {
                        uint64_t next_end = r[i + 1].off + r[i + 1].len;

                        if (next_end > end)
                                end = next_end;
                        i++;
                }

                if (max_total != 0 && locked + (end - off) > max_total) {
                        skipped += end - off;
                        continue;
                }

                if (open_path == NULL || strcmp (open_path, r[i].path) != 0) {
                        if (fd >= 0)
                                close (fd);
                        free (open_path);
                        open_path = strdup (r[i].path);
                        fd = open (r[i].path, O_RDONLY);
                }

                if (fd < 0) {
                        failed++;
                        continue;
                }

                addr = mmap (NULL, end - off, PROT_READ, MAP_SHARED, fd, (off_t) off);
                if (addr == MAP_FAILED) {
                        fprintf (stderr, "preload-pages: mmap %s: %s\n",
                                 r[i].path, strerror (errno));
                        failed++;
                        continue;
                }

                if (mlock (addr, end - off) != 0) {
                        fprintf (stderr, "preload-pages: mlock %s: %s\n",
                                 r[i].path, strerror (errno));
                        munmap (addr, end - off);
                        failed++;
                        continue;
                }

                locked += end - off;
                mapped++;
        }

        printf ("locked %" PRIu64 " KiB across %u ranges", locked / 1024, mapped);
        if (skipped != 0)
                printf (", skipped %" PRIu64 " KiB over the budget", skipped / 1024);
        if (failed != 0)
                printf (", %u failed", failed);
        printf ("\n");
        fflush (stdout);

        for (;;)
                pause ();
}

static void
usage (void)
{
        fprintf (stderr,
                 "usage: preload-pages record [--min-size BYTES] [--prefix PATH] PID...\n"
                 "       preload-pages lock [--max-total BYTES] [PROFILE...]\n");
}

int
main (int argc, char **argv)
{
        page_size = (size_t) sysconf (_SC_PAGESIZE);

        if (argc < 2) {
                usage ();
                return 1;
        }

        if (strcmp (argv[1], "record") == 0) {
                uint64_t    min_size = 0;
                const char *prefix = NULL;
                int         i = 2;

                for (; i < argc; i++) {
                        if (strcmp (argv[i], "--min-size") == 0 && i + 1 < argc)
                                min_size = strtoull (argv[++i], NULL, 10);
                        else if (strcmp (argv[i], "--prefix") == 0 && i + 1 < argc)
                                prefix = argv[++i];
                        else
                                break;
                }

                if (i == argc) {
                        usage ();
                        return 1;
                }

                for (; i < argc; i++)
                        record_pid (argv[i], min_size, prefix);

                return 0;
        }

        if (strcmp (argv[1], "lock") == 0) {
                uint64_t max_total = 0;
                int      i = 2;

                for (; i < argc; i++) {
                        if (strcmp (argv[i], "--max-total") == 0 && i + 1 < argc)
                                max_total = strtoull (argv[++i], NULL, 10);
                        else
                                break;
                }

                return lock_ranges (argv + i, argc - i, max_total);
        }

        usage ();
        return 1;
}
