(() => {
    let lastSignature = "";
    console.log("Ninji: TrackObserver.js v2.4 (URL mode)...");

    function poll() {
        try {
            const player = document.querySelector('[aria-label="Music Player"]');
            if (!player) return;

            const container = player.querySelector('[aria-label="Currently Playing"]');
            if (!container) return;

            const gameEl = container.querySelector('a[href*="/game/"]');
            const slider = player.querySelector('input[aria-label="Track position slider"]');
            const imgEl = container.querySelector('img');
            
            let titleAuthorEl = container.querySelector('span[aria-hidden="false"]');
            if (!titleAuthorEl) {
                titleAuthorEl = container.querySelector('._18gpfr94[aria-hidden="false"]') 
                             || container.querySelector('span[role="region"][tabindex="0"]');
            }

            const pauseButton = player.querySelector('button[aria-label*="Pause"]');
            const isPlaying = !!pauseButton;

            if (!titleAuthorEl || !gameEl || !slider) return;

            let titleAuthor = titleAuthorEl.innerText.trim().split("\n")[0].trim();
            const parts = titleAuthor.split(" / ");
            const name = parts[0].trim();
            const author = parts.slice(1).join(" / ").trim();
            const game = gameEl.innerText.trim();
            
            const position = parseFloat(slider.value) / 1000;
            const length = parseFloat(slider.max) / 1000;
            
            // Just send the URL, Vencord will fetch it
            const imageUrl = imgEl ? imgEl.src : null;

            const currentSignature = JSON.stringify({
                name,
                game,
                author,
                pos: Math.round(position),
                playing: isPlaying,
                img: imageUrl
            });

            if (currentSignature !== lastSignature) {
                const data = {
                    name,
                    game,
                    author,
                    image: imageUrl, 
                    position,
                    length,
                    isPlaying
                };

                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.trackObserver) {
                    window.webkit.messageHandlers.trackObserver.postMessage(data);
                    lastSignature = currentSignature;
                    console.log("Ninji: Update ->", name, (isPlaying ? "▶️" : "⏸️"));
                }
            }
        } catch (e) {
            console.error("Ninji Polling Error:", e.message);
        }
    }

    setInterval(poll, 1000);
})();
