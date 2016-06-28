1.基于AVPlayer的封装.
2.支持用户左右滑动调节进度,上下滑动控制声音.
3.支持缓冲进度条,并可以修改缓冲进度条颜色 //XHPlayerProgressView -> bufferProgressTintColor (默认是greenColor)
4.支持全屏(添加到Window上),缩放(重新添加到最初的父view)上,在初始化的时候给firstSuperView赋值
5.支持自动旋转屏幕,界面全屏和半屏展示,可以通过禁用 isAutoFullScreen 关闭此功能
6.在关闭播放器的时候,只需调用 close 方法即可.
