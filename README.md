# AudioQueueRecorder
Audio Recorder with Audio Queue.

## How to use

Please prepare before use.

````
        audioRecorder = AudioRecorder()
        audioRecorder?.prepare()
        audioRecorder?.prepareQueue()
        audioRecorder?.setupBuffer()
````

Call `startRecord` to start recording.

````
        audioRecorder?.startRecord()
````

Call `stopRecord` to stop recording.
````
        audioRecorder?.stopRecord()
````

## License

MIT license
