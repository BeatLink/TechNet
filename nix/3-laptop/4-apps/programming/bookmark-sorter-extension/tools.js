// Bookmark Tools
//
// The only things the model is allowed to do: look at loose bookmarks, name
// folders, and move bookmarks between them. Nothing reads pages or deletes.
//
const UNFILED_ROOT = "unfiled_____";

// How many bookmarks one move may touch before the sidebar asks first.
const CONFIRM_ABOVE = 10;

const TOOL_SCHEMA = [
    {
        type: "function",
        function: {
            name: "list_unfiled",
            description: "List bookmarks sitting loose in Other Bookmarks, not yet in any folder.",
            parameters: {
                type: "object",
                properties: { limit: { type: "integer", description: "How many to return, at most 60." } },
            },
        },
    },
    {
        type: "function",
        function: {
            name: "search_bookmarks",
            description: "Find bookmarks whose title or address contains the given text.",
            parameters: {
                type: "object",
                properties: {
                    query: { type: "string" },
                    limit: { type: "integer", description: "How many to return, at most 60." },
                },
                required: ["query"],
            },
        },
    },
    {
        type: "function",
        function: {
            name: "list_folders",
            description: "List the folders that already exist under Other Bookmarks, with how many bookmarks each holds.",
            parameters: { type: "object", properties: {} },
        },
    },
    {
        type: "function",
        function: {
            name: "create_folder",
            description: "Make a folder under Other Bookmarks. Does nothing if one of that name is already there.",
            parameters: { type: "object", properties: { name: { type: "string" } }, required: ["name"] },
        },
    },
    {
        type: "function",
        function: {
            name: "move_bookmarks",
            description: "Move bookmarks into a folder, by the ids returned from the listing tools.",
            parameters: {
                type: "object",
                properties: {
                    ids: { type: "array", items: { type: "string" } },
                    folder: { type: "string" },
                },
                required: ["ids", "folder"],
            },
        },
    },
];

// Trims a title to something a model can read a lot of without spending its context on it.
function short(text, width = 90) {
    return (text || "").slice(0, width);
}

// Returns the folder of that name under Other Bookmarks, making it only if it is not there.
async function folderByName(name) {
    const children = await browser.bookmarks.getChildren(UNFILED_ROOT);
    const existing = children.find((child) => !child.url && child.title === name);
    if (existing) {
        return { id: existing.id, created: false };
    }
    const made = await browser.bookmarks.create({ parentId: UNFILED_ROOT, title: name });
    return { id: made.id, created: true };
}

const TOOLS = {
    // Lists what is still loose, which is the pile the model is here to sort.
    async list_unfiled({ limit }) {
        const children = await browser.bookmarks.getChildren(UNFILED_ROOT);
        const loose = children.filter((child) => child.url);
        const capped = loose.slice(0, Math.min(limit || 40, 60));
        return {
            total_loose: loose.length,
            showing: capped.length,
            bookmarks: capped.map((b) => ({ id: b.id, title: short(b.title), host: hostOf(b.url) })),
        };
    },

    // Searches the whole tree, so the model can gather a theme rather than page through everything.
    async search_bookmarks({ query, limit }) {
        const found = await browser.bookmarks.search(query);
        const capped = found.filter((b) => b.url).slice(0, Math.min(limit || 40, 60));
        return {
            matches: capped.length,
            bookmarks: capped.map((b) => ({ id: b.id, title: short(b.title), host: hostOf(b.url) })),
        };
    },

    // Reports the folders that exist, so the model reuses them instead of inventing near-duplicates.
    async list_folders() {
        const children = await browser.bookmarks.getChildren(UNFILED_ROOT);
        const folders = children.filter((child) => !child.url);
        const counted = [];
        for (const folder of folders) {
            const inside = await browser.bookmarks.getChildren(folder.id);
            counted.push({ name: folder.title, holds: inside.length });
        }
        return { folders: counted };
    },

    async create_folder({ name }) {
        if (!name || !name.trim()) {
            return { error: "a folder needs a name" };
        }
        const { created } = await folderByName(name.trim());
        return created ? { created: name.trim() } : { already_there: name.trim() };
    },

    // Moves by id, reporting each one that no longer resolves rather than failing the batch.
    async move_bookmarks({ ids, folder }) {
        if (!Array.isArray(ids) || !ids.length) {
            return { error: "no bookmarks named" };
        }
        if (!folder || !folder.trim()) {
            return { error: "no folder named" };
        }
        const { id: target, created } = await folderByName(folder.trim());
        let moved = 0;
        const failed = [];
        for (const id of ids) {
            try {
                await browser.bookmarks.move(id, { parentId: target });
                moved += 1;
            } catch (error) {
                failed.push(id);
            }
        }
        return { moved, into: folder.trim(), folder_created: created, not_found: failed };
    },
};

// Pulls the host out of an address for the listings, since the model reads it as a strong hint.
function hostOf(url) {
    try {
        return new URL(url).host;
    } catch (error) {
        return "";
    }
}

// Reports whether a call needs the person to agree before it runs.
function needsConfirming(name, args) {
    return name === "move_bookmarks" && Array.isArray(args.ids) && args.ids.length > CONFIRM_ABOVE;
}

// Says in one line what a call is about to do, for the confirmation prompt.
function describe(name, args) {
    if (name === "move_bookmarks") {
        return `move ${args.ids.length} bookmarks into "${args.folder}"`;
    }
    if (name === "create_folder") {
        return `create the folder "${args.name}"`;
    }
    return name;
}
