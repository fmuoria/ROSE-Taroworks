import { LightningElement, api } from 'lwc';
import { saveMediaFile } from 'c/roseUtils';

export default class RoseMediaCapture extends LightningElement {
    @api formResponseId;

    handleCapturePhoto() {
        // Implement camera capture
    }

    handleGetGPS() {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition((position) => {
                const lat = position.coords.latitude;
                const lon = position.coords.longitude;
                // Save GPS coordinates
            });
        }
    }
}
