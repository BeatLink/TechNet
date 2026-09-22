// Bookmark Sorter
//
// Reads a bookmark-sorter plan and applies it to the live bookmark tree, so
// the browser need not be closed and nothing writes to places.sqlite.
//
const UNFILED = "unfiled_____";

const planInput = document.getElementById("plan");
const summaryBox = document.getElementById("summary");
const applyButton = document.getElementById("apply");
const statusBox = document.getElementById("status");

let plan = null;

// Counts how many bookmarks each folder is due to receive.
function tally(assignments) {
    const counts = new Map();
    for (const entry of assignments) {
        counts.set(entry.folder, (counts.get(entry.folder) || 0) + 1);
    }
    return [...counts.entries()].sort((a, b) => b[1] - a[1]);
}

// Shows what the loaded plan would do, before anything moves.
function showSummary() {
    summaryBox.textContent = "";
    for (const [folder, count] of tally(plan.assignments)) {
        const row = document.createElement("div");
        const name = document.createElement("span");
        const number = document.createElement("span");
        name.textContent = folder;
        number.textContent = count;
        row.append(name, number);
        summaryBox.append(row);
    }
}

// Returns the folder's id under Other Bookmarks, creating it only if it is not there already.
async function folderId(title, cache) {
    if (cache.has(title)) {
        return cache.get(title);
    }
    const children = await browser.bookmarks.getChildren(UNFILED);
    const existing = children.find((child) => !child.url && child.title === title);
    const id = existing ? existing.id : (await browser.bookmarks.create({ parentId: UNFILED, title })).id;
    cache.set(title, id);
    return id;
}

// Moves one bookmark, falling back to its URL when the recorded id no longer resolves.
async function moveOne(entry, target) {
    try {
        await browser.bookmarks.move(entry.guid, { parentId: target });
        return true;
    } catch (error) {
        const matches = entry.url ? await browser.bookmarks.search({ url: entry.url }) : [];
        const loose = matches.find((match) => match.parentId === UNFILED);
        if (!loose) {
            return false;
        }
        await browser.bookmarks.move(loose.id, { parentId: target });
        return true;
    }
}

planInput.addEventListener("change", async () => {
    const file = planInput.files[0];
    if (!file) {
        return;
    }
    try {
        plan = JSON.parse(await file.text());
        if (!Array.isArray(plan.assignments)) {
            throw new Error("no assignments in that file");
        }
    } catch (error) {
        plan = null;
        applyButton.disabled = true;
        statusBox.className = "bad";
        statusBox.textContent = `Could not read that plan: ${error.message}`;
        return;
    }
    statusBox.textContent = "";
    statusBox.className = "";
    showSummary();
    applyButton.disabled = false;
});

applyButton.addEventListener("click", async () => {
    applyButton.disabled = true;
    planInput.disabled = true;
    const cache = new Map();
    let moved = 0;
    const missing = [];
    for (const entry of plan.assignments) {
        const target = await folderId(entry.folder, cache);
        if (await moveOne(entry, target)) {
            moved += 1;
        } else {
            missing.push(entry.title || entry.url);
        }
        statusBox.textContent = `Moved ${moved} of ${plan.assignments.length}...`;
    }
    statusBox.textContent = `Moved ${moved} of ${plan.assignments.length} into ${cache.size} folders.`;
    if (missing.length) {
        statusBox.className = "bad";
        statusBox.textContent += `\nLeft alone, no longer in Other Bookmarks:\n- ${missing.slice(0, 10).join("\n- ")}`;
    }
    planInput.disabled = false;
});
