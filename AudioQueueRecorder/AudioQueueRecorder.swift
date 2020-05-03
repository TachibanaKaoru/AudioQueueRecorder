//
//  AudioQueueRecorder.swift
//  AudioQueueRecorder
//
//  Created by Kaoru Tachibana on 2020/05/03.
//  Copyright © 2020 Toyship.org. All rights reserved.
//

import Foundation
import AudioToolbox

class AudioQueueRecorder {
    
    private var dataFormat: AudioStreamBasicDescription!

    private var audioQueue: AudioQueueRef!

    private var buffers: [AudioQueueBufferRef]

    private var audioFile: AudioFileID!
    
    private var bufferByteSize: UInt32

    private var currentPacket: Int64

    private var isRunning: Bool

    init(){

        buffers = []
        bufferByteSize = 0
        currentPacket = 0
        isRunning = false

    }
    
    var currentMusicDataFormat = AudioStreamBasicDescription(
        mSampleRate: 44100,
        mFormatID: kAudioFormatLinearPCM,
        mFormatFlags: AudioFormatFlags(kLinearPCMFormatFlagIsBigEndian|kLinearPCMFormatFlagIsSignedInteger|kLinearPCMFormatFlagIsPacked),
        mBytesPerPacket: 4,
        mFramesPerPacket: 1,
        mBytesPerFrame: 4,
        mChannelsPerFrame: 2,
        mBitsPerChannel: 16,
        mReserved: 0)

    let myAudioCallback: AudioQueueInputCallback = { (
        inUserData:Optional<UnsafeMutableRawPointer>,
        inAQ:AudioQueueRef,
        inBuffer:UnsafeMutablePointer<AudioQueueBuffer>,
        inStartTime:UnsafePointer<AudioTimeStamp>,
        inNumPackets:UInt32,
        inPacketDesc:Optional<UnsafePointer<AudioStreamPacketDescription>>) -> ()  in
        
        guard let userData = inUserData else{
            assert(false, "no user data...")
            return
        }
        
        let unManagedUserData = Unmanaged<AudioQueueRecorder>.fromOpaque(userData)
        let receivedUserData = unManagedUserData.takeUnretainedValue()
        
        receivedUserData.writeToFile(
            buffer: inBuffer,
            numberOfPackets: inNumPackets ,
            inPacketDesc: inPacketDesc)
        
        if !(receivedUserData.isRunning) {
            return
        }
        
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
        
    }
    
    func prepare(){
        
        dataFormat = currentMusicDataFormat
        
        var aAudioFileID: AudioFileID?
        
        let documentDirectories = FileManager.default.urls(
            for: FileManager.SearchPathDirectory.documentDirectory,
            in: FileManager.SearchPathDomainMask.userDomainMask)
        let docDirectory = (documentDirectories.first)!
        
        var audioFilePathURL = docDirectory.appendingPathComponent("audiotest")
        audioFilePathURL.appendPathExtension("aiff")
        
        AudioFileCreateWithURL(audioFilePathURL as CFURL,
                               kAudioFileAIFFType,
                               &currentMusicDataFormat,
                               AudioFileFlags.eraseFile,
                               &aAudioFileID)

        audioFile = aAudioFileID!
    }
    
    func prepareQueue(){
                
        var aQueue: AudioQueueRef!
                        
        AudioQueueNewInput(
            &currentMusicDataFormat,
            myAudioCallback,
            unsafeBitCast(self, to: UnsafeMutableRawPointer.self),
            .none,
            CFRunLoopMode.commonModes.rawValue,
            0,
            &aQueue)
        
        if let aQueue = aQueue{
            audioQueue = aQueue
        }
        
    }
    
    func startRecord(){
        
        currentPacket = 0
        isRunning = true
        
        AudioQueueStart(audioQueue, nil)
        
    }
    
    func stopRecord(){
        
        isRunning = false
        
        AudioQueueStop(audioQueue, true)
        AudioQueueDispose(audioQueue, true)
        
        closeFile()
    }
    
    func writeToFile(buffer: UnsafeMutablePointer<AudioQueueBuffer>,numberOfPackets:UInt32,inPacketDesc:Optional<UnsafePointer<AudioStreamPacketDescription>>){
        
        guard let audioFile = audioFile else{
            assert(false, "no audio data...")
            return
        }
        
        var newNumPackets: UInt32 = numberOfPackets
        if (numberOfPackets == 0 && dataFormat.mBytesPerPacket != 0){
            newNumPackets = buffer.pointee.mAudioDataByteSize / dataFormat.mBytesPerPacket
        }
        
        let inNumPointer = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        inNumPointer.initialize(from: &newNumPackets, count: 1)
        
        let writeResult = AudioFileWritePackets(audioFile,
                              false,
                              buffer.pointee.mAudioDataByteSize,
                              inPacketDesc,
                              currentPacket,
                              inNumPointer,
                              buffer.pointee.mAudioData)
        
        currentPacket += Int64(numberOfPackets)
        
        if writeResult != noErr{
            // handle error
        }
        
    }
    
    func closeFile(){
        
        if let audioFile = audioFile{
            AudioFileClose(audioFile)
        }
    }
    
    func setupBuffer(){
        
        // typically 3
        let kNumberBuffers: Int = 3

        // typically 0.5
        bufferByteSize = deriveBufferSize(audioQueue: audioQueue, audioDataFormat: currentMusicDataFormat, seconds: 0.5)

        for i in 0..<kNumberBuffers{
            
            var newBuffer: AudioQueueBufferRef? = nil
            
            AudioQueueAllocateBuffer(
                audioQueue,
                bufferByteSize,
                &newBuffer)
            
            if let newBuffer = newBuffer{
                buffers.append(newBuffer)
            }
            
            AudioQueueEnqueueBuffer(
                audioQueue,
                buffers[i],
                0,
                nil)
            
        }
        
    }

    func deriveBufferSize(audioQueue: AudioQueueRef, audioDataFormat: AudioStreamBasicDescription, seconds: Float64) -> UInt32{
        
        let maxBufferSize:UInt32 = 0x50000
        var maxPacketSize:UInt32 = audioDataFormat.mBytesPerPacket
        
        if (maxPacketSize == 0) {
            
            var maxVBRPacketSize = UInt32(MemoryLayout<UInt32>.size)
            AudioQueueGetProperty(audioQueue, kAudioQueueProperty_MaximumOutputPacketSize, &maxPacketSize, &maxVBRPacketSize)
            
        }
        
        let numBytesForTime = UInt32(Float64(audioDataFormat.mSampleRate) * Float64(maxPacketSize) * Float64(seconds))
        let outBufferSize = UInt32(numBytesForTime < maxBufferSize ? numBytesForTime : maxBufferSize)
        
        return outBufferSize
    }
}
