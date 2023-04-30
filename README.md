**This problem fixed above iOS16.4 by Apple :)**

# PiP Battery Drain

Sample project to reproduce PiP batery drain.

<kbd><img src="https://user-images.githubusercontent.com/5572875/216527470-ac58e411-585a-463f-aec3-4771e03698fe.gif" width="300"></kbd>

## Detail

Problem that Picture-in-Picture incredibly use cpu resource on device above iOS16.1 is widely known.

- https://www.reddit.com/r/iphone/comments/yt5jgn/ios_1611_battery_drain/
- https://www.reddit.com/r/iOSBeta/comments/xvw6br/ios_161_developer_beta_4_iphone_14_pro_max_pip/
- https://forums.macrumors.com/threads/excessive-heat-while-using-youtube-pip.2367421/

I found PiP use huge cpu resource only when return specific value in a function related with `AVPictureInPictureSampleBufferPlaybackDelegate`.

```swift
func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
  // CPU usage become over 100% when return `false` here.
  return false
}
```

PiP will calm down if developers return `true` in above function, but developers control Play and Pause mark on video contents in PiP through that delegate method.

This is only the short term solution and there is tradeoff between user-control of contents and problem of battery.
