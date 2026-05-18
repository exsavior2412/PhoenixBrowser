import Foundation

enum FingerprintProtection {
    static var script: String {
        """
        (function() {
            Object.defineProperty(screen, 'width', { get: () => 1920 });
            Object.defineProperty(screen, 'height', { get: () => 1080 });
            Object.defineProperty(screen, 'availWidth', { get: () => 1920 });
            Object.defineProperty(screen, 'availHeight', { get: () => 1080 });
            Object.defineProperty(screen, 'colorDepth', { get: () => 24 });

            const origToDataURL = HTMLCanvasElement.prototype.toDataURL;
            HTMLCanvasElement.prototype.toDataURL = function(type) {
                if (this.width > 16 && this.height > 16) {
                    const ctx = this.getContext('2d');
                    if (ctx) {
                        const d = ctx.getImageData(0, 0, this.width, this.height);
                        for (let i = 0; i < d.data.length; i += 4) { d.data[i] ^= 1; }
                        ctx.putImageData(d, 0, 0);
                    }
                }
                return origToDataURL.apply(this, arguments);
            };

            const gp = WebGLRenderingContext.prototype.getParameter;
            WebGLRenderingContext.prototype.getParameter = function(p) {
                if (p === 37445) return 'Apple';
                if (p === 37446) return 'Apple GPU';
                return gp.apply(this, arguments);
            };

            Object.defineProperty(navigator, 'hardwareConcurrency', { get: () => 8 });
            Object.defineProperty(navigator, 'deviceMemory', { get: () => 8 });
            Object.defineProperty(navigator, 'maxTouchPoints', { get: () => 0 });
            if (navigator.getBattery) { navigator.getBattery = undefined; }
        })();
        """
    }
}
