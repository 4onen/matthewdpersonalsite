
window.addEventListener("DOMContentLoaded", () => {
    const announcements = document.querySelector("#announcements");
    const editor = document.querySelector("#announcement-input");

    if (!(announcements && editor)) {
        console.error("Missing required element from announcements.mjs", { announcements, editor });
    }

    editor.innerText = localStorage.getItem("announcement") || announcements.innerHTML;

    const updateAnnouncements = () => {
        const contents = editor.value;
        localStorage.setItem("announcement", contents);
        announcements.innerHTML = contents;
    };

    updateAnnouncements();

    editor.addEventListener("input", updateAnnouncements)
});