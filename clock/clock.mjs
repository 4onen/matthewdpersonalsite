const TIME_OPTIONS = {
    hour12: true,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
}

const DATE_OPTIONS = {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: '2-digit',
};

window.addEventListener("DOMContentLoaded", () => {
    const time = document.querySelector("#time");
    const date = document.querySelector("#date");

    if (!(time && date)) {
        console.error("Missing required element from clock.mjs", { time, date });
    }

    let lastDate = null;

    const updateDateTime = () => {
        const now = new Date();
        time.innerText = now.toLocaleTimeString(undefined, TIME_OPTIONS);

        const nowDate = now.toLocaleDateString(undefined, DATE_OPTIONS);
        if (nowDate !== lastDate) {
            date.innerText = nowDate;
            lastDate = nowDate;
        }
    };

    if (time && date) {
        updateDateTime();
        setInterval(updateDateTime, 1000);
    }
});