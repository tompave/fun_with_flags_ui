document
.querySelectorAll("[data-confirm]")
.forEach((item) => {
    item.addEventListener("click", (e) => {
        if (confirm(e.target.dataset.confirm)) {
            return true;
        } else {
            e.preventDefault();
            return false;
        }
    });
});
