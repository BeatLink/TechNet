// Bookmark Chat
//
// Talks to the model on the LM Studio server and lets it call the bookmark
// tools, so bookmarks are sorted in conversation rather than from a plan.
//
const ENDPOINT = "http://127.0.0.1:1234";
const MAX_ROUNDS = 8;

const SYSTEM = `You tidy the bookmarks in this browser through the tools you are given.

Work in small steps. Look before you move: list what is loose or search for a theme, check which folders
exist, then move by the ids the listings gave you. Reuse an existing folder rather than making one that
nearly matches. Prefer one move of many ids over many single moves.

Ids are opaque, so never invent one. Say briefly what you did; do not list every bookmark back.`;

const logBox = document.getElementById("log");
const modelLabel = document.getElementById("model");
const input = document.getElementById("input");
const sendButton = document.getElementById("send");
const confirmBox = document.getElementById("confirm");
const confirmText = document.getElementById("confirm-text");

let model = null;
let messages = [{ role: "system", content: SYSTEM }];
let pending = null;

// Puts a line in the transcript and keeps the newest in view.
function say(text, kind) {
    const line = document.createElement("div");
    line.className = `msg ${kind || ""}`;
    line.textContent = text;
    logBox.append(line);
    logBox.scrollTop = logBox.scrollHeight;
    return line;
}

// Asks the server which model is loaded, since that is the one the chat should address.
async function findModel() {
    const reply = await fetch(`${ENDPOINT}/v1/models`);
    const body = await reply.json();
    const first = (body.data || [])[0];
    if (!first) {
        throw new Error("no model loaded");
    }
    return first.id;
}

// Sends the conversation so far and returns the assistant's next message.
async function turn() {
    const reply = await fetch(`${ENDPOINT}/v1/chat/completions`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ model, messages, tools: TOOL_SCHEMA, temperature: 0.2, max_tokens: 4000 }),
    });
    if (!reply.ok) {
        throw new Error(`the server answered ${reply.status}`);
    }
    const body = await reply.json();
    return body.choices[0].message;
}

// Runs one tool call and appends what it returned, so the model sees the outcome.
async function runCall(call) {
    const name = call.function.name;
    let args = {};
    try {
        args = JSON.parse(call.function.arguments || "{}");
    } catch (error) {
        args = {};
    }
    const tool = TOOLS[name];
    let result;
    if (!tool) {
        result = { error: `no such tool: ${name}` };
    } else {
        try {
            result = await tool(args);
        } catch (error) {
            result = { error: error.message };
        }
    }
    say(`${describe(name, args)} → ${JSON.stringify(result).slice(0, 220)}`, "tool");
    messages.push({ role: "tool", tool_call_id: call.id, content: JSON.stringify(result) });
}

// Holds a call that touches too much to run unasked, and waits for the answer.
function askFirst(call, args) {
    return new Promise((resolve) => {
        confirmText.textContent = `The model wants to ${describe(call.function.name, args)}.`;
        confirmBox.classList.add("show");
        pending = (agreed) => {
            confirmBox.classList.remove("show");
            pending = null;
            resolve(agreed);
        };
    });
}

// Drives the exchange until the model stops asking for tools.
async function converse() {
    for (let round = 0; round < MAX_ROUNDS; round += 1) {
        const message = await turn();
        messages.push(message);

        if (!message.tool_calls || !message.tool_calls.length) {
            say(message.content || "(nothing said)");
            return;
        }

        for (const call of message.tool_calls) {
            let args = {};
            try {
                args = JSON.parse(call.function.arguments || "{}");
            } catch (error) {
                args = {};
            }
            if (needsConfirming(call.function.name, args)) {
                if (!(await askFirst(call, args))) {
                    say(`declined: ${describe(call.function.name, args)}`, "tool");
                    messages.push({
                        role: "tool",
                        tool_call_id: call.id,
                        content: JSON.stringify({ declined: "the person said no; ask what they would prefer" }),
                    });
                    continue;
                }
            }
            await runCall(call);
        }
    }
    say("stopped after too many tool rounds; say what to do next", "bad");
}

document.getElementById("yes").addEventListener("click", () => pending && pending(true));
document.getElementById("no").addEventListener("click", () => pending && pending(false));

sendButton.addEventListener("click", async () => {
    const text = input.value.trim();
    if (!text || !model) {
        return;
    }
    input.value = "";
    say(text, "you");
    messages.push({ role: "user", content: text });
    sendButton.disabled = true;
    const waiting = say("thinking…", "tool");
    try {
        await converse();
    } catch (error) {
        say(error.message, "bad");
    } finally {
        waiting.remove();
        sendButton.disabled = false;
        input.focus();
    }
});

input.addEventListener("keydown", (event) => {
    if (event.key === "Enter" && (event.ctrlKey || event.metaKey)) {
        sendButton.click();
    }
});

findModel().then(
    (found) => {
        model = found;
        modelLabel.textContent = found;
    },
    (error) => {
        modelLabel.textContent = "no model";
        modelLabel.className = "bad";
        say(`Cannot reach a model at ${ENDPOINT}: ${error.message}\nStart LM Studio's server with: lms server start`, "bad");
    },
);
