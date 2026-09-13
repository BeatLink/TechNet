// Keeps Home Assistant's fan speed buttons for a four-speed fan, which the stock frontend hands to a slider.
// Loaded on every page through frontend.extra_module_url and swaps the render of the two speed controls.

const SPEEDS = [
    ["Off", "mdi:fan-off"],
    ["Low", "mdi:fan-speed-1"],
    ["Medium", "mdi:fan-speed-2"],
    ["High", "mdi:fan-speed-3"],
    ["Max", "mdi:fan"],
];

const hass = () => document.querySelector("home-assistant")?.hass;

// Mirrors the stock count, which treats Off as one of the steps.
const speedCount = (stateObj) => Math.round(100 / (stateObj.attributes.percentage_step ?? 1)) + 1;

// Index of the button matching the fan's current percentage, as the string value ha-control-select compares.
const currentIndex = (stateObj) => {
    const step = stateObj.attributes.percentage_step ?? 1;
    const percentage = stateObj.state === "on" ? (stateObj.attributes.percentage ?? 0) : 0;
    return String(Math.round(percentage / step));
};

// Turns a pressed button back into the percentage the fan integration expects.
const select = (stateObj, ev) => {
    const step = stateObj.attributes.percentage_step ?? 1;
    const percentage = Math.min(100, Math.round(Number(ev.detail.value) * step));
    hass()?.callService("fan", "set_percentage", { entity_id: stateObj.entity_id, percentage });
};

// Replaces the element's render with the button list whenever the fan has exactly the speeds listed above.
const patch = (tag, getState, vertical) =>
    customElements.whenDefined(tag).then(() => {
        const proto = customElements.get(tag).prototype;
        const html = proto.html;
        if (typeof html !== "function") {
            console.warn(`fan-speed-buttons: ${tag} exposes no html helper, leaving it alone`);
            return;
        }
        const render = proto.render;
        proto.render = function () {
            const stateObj = getState(this);
            if (!stateObj || speedCount(stateObj) !== SPEEDS.length) return render.call(this);
            const options = SPEEDS.map(([label, icon], i) => ({
                value: String(i),
                label,
                icon: html`<ha-icon .icon=${icon}></ha-icon>`,
            }));
            const color = stateObj.state === "on"
                ? "var(--state-fan-active-color, var(--state-active-color))"
                : "var(--state-inactive-color)";
            return html`<ha-control-select
                ?vertical=${vertical}
                ?hide-option-label=${!vertical}
                .options=${vertical ? options.reverse() : options}
                .value=${currentIndex(stateObj)}
                .disabled=${stateObj.state === "unavailable"}
                style="--control-select-color: ${color}; --control-select-background: ${color};"
                @value-changed=${(ev) => select(stateObj, ev)}
            ></ha-control-select>`;
        };
    });

patch("ha-state-control-fan-speed", (el) => el.stateObj, true);
patch("hui-fan-speed-card-feature", (el) => hass()?.states[el.context?.entity_id], false);
