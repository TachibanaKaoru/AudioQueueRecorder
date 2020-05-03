# AudioQueueRecorder
Swift Audio Recorder with Audio Queue.

## Requirements

- Xcode 11+
- Swift 5.1+

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
