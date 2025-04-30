if (
    localStorage.getItem("color-mode") === "dark" ||
    (window.matchMedia("(prefers-color-scheme: dark)").matches &&
        !localStorage.getItem("color-mode"))
) {

    document.documentElement.setAttribute("color-mode", "dark");
    console.log("Mode by default:", localStorage.getItem("color-mode"))
} else {
    document.documentElement.setAttribute("color-mode", "light");
}

$(document).ready(function() {
    if (window.CSS && CSS.supports("color", "var(--primary)")) {
        var toggleColorMode = function toggleColorMode(e) {
            // Switch to Light Mode
            console.log(localStorage.getItem("color-mode"))
            if (e.currentTarget.classList.contains("light--hidden")) {
                // Sets the custom html attribute
                document.documentElement.setAttribute("color-mode", "light"); // Sets the user's preference in local storage

                localStorage.setItem("color-mode", "light");
                return;
            }
            /* Switch to Dark Mode
            Sets the custom html attribute */
            document.documentElement.setAttribute("color-mode", "dark"); // Sets the user's preference in local storage

            localStorage.setItem("color-mode", "dark");


        }; // Get the buttons in the DOM

        var toggleColorButtons = document.querySelectorAll(".color-mode__btn"); // Set up event listeners

        toggleColorButtons.forEach(function(btn) {
            btn.addEventListener("click", toggleColorMode);
        });
    } else {
        // If the feature isn't supported, then we hide the toggle buttons
        var btnContainer = document.querySelector(".color-mode__header");
        if (btnContainer) {
            btnContainer.style.display = "none";
        }
    }
});