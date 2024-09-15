"use strict";

const fmtdate = (d) => d.getFullYear()+"-"+String(1+d.getMonth()).padStart(2,"0")+"-"+String(d.getDate()).padStart(2,"0");
const fmttime = (d) => String(d.getHours()).padStart(2,"0")+":"+String(d.getMinutes()).padStart(2,"0");

const TIMESTAMP_CODES = [
    ["R", (date) => {
        const now = new Date();
        const diff = Math.floor((now - date) / 1000);
        if (Math.abs(diff) < 1) return "Just now";
        if (diff > 0) {
            if (diff < 60) return `${diff} seconds ago`;
            if (diff < 120) return `a minute ago`;
            if (diff < 60*60) return `${Math.floor(diff / 60)} minutes ago`;
            if (diff < 60*60*2) return `an hour ago`;
            if (diff < 60*60*24) return `${Math.floor(diff / 60 / 60)} hours ago`;
            if (diff < 60*60*24*365.25) return `${Math.floor(diff / 60 / 60 / 24)} days ago`;
            if (diff < 60*60*24*365.25*100) return `${Math.floor(diff / 60 / 60 / 24 / 365.25)} years ago`;
        } else {
            if (diff > -60) return `in ${-diff} seconds`;
            if (diff > -120) return `in a minute`;
            if (diff > -60*60) return `in ${-Math.floor(diff / 60)} minutes`;
            if (diff > -60*60*2) return `in an hour`;
            if (diff > -60*60*24) return `in ${-Math.floor(diff / 60 / 60)} hours`;
            if (diff > -60*60*24*365.25) return `in ${-Math.floor(diff / 60 / 60 / 24)} days`;
            if (diff > -60*60*24*365.25*100) return `in ${-Math.floor(diff / 60 / 60 / 24 / 365.25)} years`;
        }
        return "Unknown";
    }],
    ["d", (date) => date.toLocaleString(undefined, {month: 'numeric', day: 'numeric', year: 'numeric'})],
    ["D", (date) => date.toLocaleString(undefined, {month: 'long', day: 'numeric', year: 'numeric'})],
    ["f", (date) => date.toLocaleString(undefined, {month: 'long', day: 'numeric', year: 'numeric', hour: 'numeric', minute: 'numeric'})],
    ["F", (date) => date.toLocaleString(undefined, {weekday: 'long', month: 'long', day: 'numeric', year: 'numeric', hour: 'numeric', minute: 'numeric'})],
    ["t", (date) => date.toLocaleTimeString(undefined, {hour: '2-digit', minute: '2-digit'})],
    ["T", (date) => date.toLocaleTimeString(undefined, {hour: '2-digit', minute: '2-digit', second: '2-digit'})],
];

const headTemplate = document.createElement('template');
headTemplate.innerHTML = `<style>
* {
    box-sizing: border-box;
}

:host {
    display: block;
    width: 100%;
    max-width: 600px;
    --input-font-size: 1.8em;
}

button {
    font-size: var(--input-font-size);
    vertical-align: top;
    height: 100%;
}

input {
    font-size: var(--input-font-size);
    vertical-align: top;
    height: 2em;
}

table {
    width: 100%;
    tr {
        width: 100%;

        td:first-child {
            text-align: center;
            font-family: monospace;
            font-size: 1.2em;
            padding: 1em;
        }
    }
}

.copyable {
    position: relative;
    background-color: rgba(0,0,0,.1);
    transition: background-color .2s;
}

.copyable:hover {
    background-color: rgba(1,1,1,.2);
}

.copyable::after {
    content: "Copied!";
    position: absolute;
    bottom: 0;
    right: 0;
    opacity: 0;
    transition: opacity 1.5s;
}

.copyable.copied::after {
    opacity: 1;
    transition: opacity .1s;
}

</style>
<input type="date" name="datetime"/><input type="time" name="datetime"/><button>Now</button>
<table></table>
`;

class DiscordTimestampGenerator extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: 'open' });
        this.shadowRoot.appendChild(headTemplate.content.cloneNode(true));
        this.datein = this.shadowRoot.querySelector('input[type="date"]');
        this.timein = this.shadowRoot.querySelector('input[type="time"]');
        this.datein.addEventListener('change', this.updateResults.bind(this));
        this.timein.addEventListener('change', this.updateResults.bind(this));
        this.results = this.shadowRoot.querySelector('table');
        this.shadowRoot.addEventListener('click', (e) => {
            if (e.target.classList.contains('copyable')) {
                navigator.clipboard.writeText(e.target.textContent);
                e.target.classList.add('copied');
            }
        });
        this.shadowRoot.addEventListener('transitionend', (e) => {
            if (e.propertyName === 'opacity') {
                e.target.classList.remove('copied');
            }
        });
        this.shadowRoot.querySelector('button').addEventListener('click', this.resetTime.bind(this));
    }

    updateResults() {
        const date = new Date(this.datein.value+"T"+this.timein.value);
        this.results.replaceChildren();
        for (const [code, func] of TIMESTAMP_CODES) {
            const row = this.results.insertRow();
            const code_cell = row.insertCell();
            code_cell.classList.add('copyable');
            const result_cell = row.insertCell();
            const timestamp = date.getTime() / 1000;
            code_cell.textContent = `<t:${timestamp}:${code}>`;
            result_cell.innerHTML = `<time datetime="${fmtdate(date)}T${fmttime(date)}">${func(date)}</time>`;
        }
    }

    resetTime () {
        const d = new Date();
        this.datein.value = fmtdate(d);
        this.timein.value = fmttime(d);
        this.updateResults();
    }

    connectedCallback() {
        this.resetTime();
    }
}

customElements.define('discord-timestamp-gen', DiscordTimestampGenerator);
