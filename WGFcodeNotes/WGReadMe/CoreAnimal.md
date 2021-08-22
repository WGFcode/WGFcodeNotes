## CoreAnimal
#### Core Animal我们知道的仅仅是用来做动画的,但是动画只是它的冰山一角,它是一个复合引擎,主要职责就是尽可能的组合屏幕上不同的可视试图.这里就涉及到视图和图层的概念了

### 一.图层树
#### 视图:所有的视图都是从UIView派生而来的,视图在层级关系中可以相互嵌套,一个视图可以管理它所有子视图的位置,UIView可以处理触碰事件/支持基于Core Graphics绘图/仿射变换(旋转,缩放等)/简单的滑动或渐变的动画
#### 图层: 图层即CALayer,和UIView类似,同样也是被层级关系树管理的矩形块,一个图层可以管理它所有子图层的位置,和UIView最大的不同在于图层CALayer不能处理用户交互,因为它不清楚具体的响应链,所以不能响应事件,但是它提供了一些方法来判断触碰点是否在一个图层的范围内.
#### 层级关系: 视图有视图层级,图层有图层树,它们是一个平行的层级关系,每个UIView都包含了一个图层CALayer,视图UIView的职责就是创建并管理这个图层,来确保当子视图在层级关系中添加或移除时,和它们关联的图层在对应的图层关系树中也有相同的操作
#### 为什么提供了UIVIew和CALayer两个平行的层级关系?如果说CALayer是UIView内容实现细节,苹果已经在UIView层面提供了接口,为什么还需要CALayer?
1. 主要就是为了职责分离,避免重复代码
2. 除了CALayer不能处理触摸事件,CALayer还可以做一些UIView不能做的工作,比如阴影/圆角/带颜色边框/3D变换/透明遮罩/多级非线形动画等

### 二.寄宿图
#### 下面例子中我们通过创建图层,设置背景色来创建了一个正方形,除了设置背景色,CALayer还支持显示我们想要的图片,即CALayer的寄宿图(图层中包含的图片)
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        //1.设置图层的背景颜色
        let layer1 = CALayer()
        layer1.frame = CGRect.init(x: 100, y: 100, width: 100, height: 100)
        layer1.backgroundColor = UIColor.red.cgColor
        self.view.layer.addSublayer(layer1)
        
        //2.设置图层的寄宿图
        let layer2 = CALayer()
        layer2.backgroundColor = UIColor.red.cgColor
        layer2.frame = CGRect(x: 100, y: 300, width: 200, height: 100)
        //contents属性:设置寄宿图,如果设置类型不是CGImage,会得到一张空白的图层
        layer2.contents = UIImage(named: "car")!.cgImage
        //如果图片有点变形,在UIImageView时有contentMode属性,而在图层对应的就是contentsGravity属性
        //contentsGravity属性决定内容在图层的边界中这么对齐
        //layer2.contentsGravity = .resizeAspect
        //contentsScale定义了寄宿图的像素尺寸和图层大小的比例,默认1.0,会以每个点X像素绘制图片(Retina屏)
        //设置并不会有太多影响,因为我们设置了contentsGravity,图片已经自处理拉伸适应图层了
        layer2.contentsScale = 1.0
        //是否裁剪超出图层边界的内容
        layer2.masksToBounds = true
        //采用的是单位坐标,默认是[0,0,1,1],就是寄宿图可以完全显示出来,如果设置为[0.5,0.5,0.5,0.5]
        //那么在整个图层中显示的就是右下角的内容,其实就是用于裁剪.该属性经常用于[图片拼合]
        //图片拼合一般应用于游戏中,但一般都是通过OpenGL来实现的
        layer2.contentsRect = CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        //定义了一个固定边框和一个在图层上可拉伸的区域,它的改变并不影响寄宿图的显示,除非这个图层的大小改变
        layer2.contentsCenter = CGRect(x: 0.5, y: 0.5, width: 0.5, height: 0.5)
        self.view.layer.addSublayer(layer2)
    }
### 三. Custom Drawing

#### 给contents属性赋CGImage类型来设置寄宿图,不是唯一的方式,还可以通过Core Graphics直接绘制寄宿图, 通过继承UIView并实现drawRect:方法.drawRect没有默认的实现,因为对于UIView来说,寄宿图并不是必须的.如果UIView检测到drawRect方法被调用了,就会为视图分配一个寄宿图,寄宿图的像素和尺寸等于视图大小乘contentsScale的值,如果你不需要寄宿图,就不要创建了,因为会造成CPU资源和内存的浪费,所以苹果建议:如果没有自定义绘制的任务就不要在视图中写一个空的drawRect方法.当视图出现在屏幕上时,drawRect方法就会被自动调用,drawRect方法里面的代码利用Core Graphics去绘制一个寄宿图,然后内容被缓存起来直到它需要被更新(调用setNeedDisplay方法),drawRect虽然是UIVIew的方法,但事实上都是底层CALayer安排了重绘工作和保存了因此产生的图片

#### CALayer有一个可选的delegate属性,当需要被重绘时,CALayer会请求它的代理给它一个寄宿图来显示,通过调用display(_ layer: CALayer)方法来实现,如果代理想直接设置contents属性,就可以这么做,不然没有别的方法可以调用了,如果代理不实现display(_ layer: CALayer)方法,CALayer就会尝试调用draw(_ layer: CALayer, in ctx: CGContext)方法,在调用这个方法前,CALayer会创建一个合适尺寸的空寄宿图和一个Core Graphics的绘制上下文环境,为绘制寄宿图做准备,
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        //1.设置图层的背景颜色
        let layer1 = CALayer()
        layer1.frame = CGRect.init(x: 100, y: 100, width: 100, height: 100)
        layer1.backgroundColor = UIColor.red.cgColor
        layer1.delegate = self
        self.view.layer.addSublayer(layer1)
        //图层显示在屏幕上时,CALayer不会自动重绘它的内容,重绘的决定权交给了开发者,所以需要  
        显示的调用,否则重绘的内容不会显示
        layer1.display()
    }
    //CALayerDelegate方法
    public func draw(_ layer: CALayer, in ctx: CGContext) {
        ctx.setLineWidth(5)
        ctx.setStrokeColor(UIColor.blue.cgColor)
        ctx.strokeEllipse(in: layer.bounds)
    }
#### 实际开发中几乎没有机会用到CALayerDelegate代理中的方法,因为当UIView创建了它的宿主图层时,会自动把图层的delegete设置为它自己,并提供了displayLayer的实现,我们直接用就行了.当使用寄宿了视图的图层时,你不需要实现display(_ layer: CALayer)和draw(_ layer: CALayer, in ctx: CGContext)方法来绘制你的寄宿图,通常做法是实现UIView的drawRect方法,UIView会帮你完成剩下的工作,包括需要重绘时调用display方法
        
### 四.图层的几何学
### 1.布局
#### UIView有三个重要的布局属性frame/bounds/center,图层CALayer对应的有frame/bounds/position,为了区分图层用的position,视图用了center,但它们都代表同样的值,frame代表了图层的外部坐标(父图层上占据的空间),bounds是内部坐标(通常是图层的左上角),center和position代表了相对于父图层anchorPoint(锚点)所在的位置.视图的三个布局属性仅仅是存取方法,当操作视图的frame时,实际上是在改变位于视图下面CALayer的frame,不能独立于图层之外改变视图的frame
#### 对于视图或图层,frame其实是个虚拟属性,时根据bounds/position/transform计算而来的,其实任何值改变,frame都会发生变化.需要特别注意的就是,当图层做变换时(旋转/缩放),frame实际代表了覆盖在图层旋转后整个轴对齐的矩形区域,也就是说frame的宽高可能和bounds的宽高不再一致了,所以如果有人说frame的宽高和bounds宽高始终相等时错误的.

#### 锚点anchorPoint:视图的center属性和图层的position属性都指定了锚点相对父图层的位置,图层的anchorPoint通过position来控制它的frame位置,可以认为anchorPoint时用来移动图层的把柄.anchorPoint默认位于图层的中点.锚点坐标是用单位坐标来表述的,默认是(0.5,0.5),如果设置锚点(0,0),那么图层就会左上角移动

#### iOS系统中用到的坐标系统
1. 点坐标:点就像虚拟的像素,也被称为逻辑像素,在标准设备中,一个点就是一个像素,但在Retina设备上,一个点等于2个像素
2. 像素坐标: 是一个物理像素坐标,实际屏幕布局中并不会用物理像素,而是用带你来度量,但一些底层的图片表示(CGImage)就会使用像素,所以要清楚在普通设备和Retina设备上,它们表现出来了不同的大小
3. 单位坐标:对于与图片大小或是图层边界相关的显示,比如前面提到的contentRect/锚点等都用到了单位坐标,单位坐标在OpenGL这种纹理坐标系统中用的很多,Core Animal中也用到了单位坐标
### 2. 坐标系
#### 和视图一样,图层在图层树当中也是相对于父图层按层级关系放置的,如果父图层发生了移动,它所有的子图层都会跟着移动,并且系统也提供了和图层的绝对位置/相对于另一个图层的位置的方法
    open func convert(_ p: CGPoint, from l: CALayer?) -> CGPoint
    open func convert(_ p: CGPoint, to l: CALayer?) -> CGPoint
    open func convert(_ r: CGRect, from l: CALayer?) -> CGRect
    open func convert(_ r: CGRect, to l: CALayer?) -> CGRect
    
### 3.Z坐标轴
#### 和UIView严格的二维坐标系不同,CALayer存在于一个三维空间当中,除了position/anchorPoint属性外,还有zPosition和anchorPointZ,这两个都是在Z轴上描述图层位置的浮点类型.其实zPosition并不常用,除了做图层变换之外,它最实用的功能就是改变图层的显示顺序了.这里需要注意的就是zPosition只能改变屏幕中图层的显示顺序,但不能改变事件传递的顺序
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let redLayer = CALayer()
        redLayer.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        redLayer.backgroundColor = UIColor.red.cgColor
        self.view.layer.addSublayer(redLayer)
        
        let blueLayer = CALayer()
        blueLayer.frame = CGRect(x: 140, y: 160, width: 100, height: 100)
        blueLayer.backgroundColor = UIColor.blue.cgColor
        self.view.layer.addSublayer(blueLayer)
        //目前显示的是蓝色在前面,红色在后面,如果想让红色在前面可以这么设置
        //这里就是将红色的zPosition提高了一个像素
        redLayer.zPosition = 1
    }
### 4. Hit-Testing
#### CALayer并不关心任何响应链事件,所以不能直接处理触摸事件或手势,但是它有一系列方法帮你处理事件:  contains(_ p: CGPoint)和
    //判断点击是否在红色的图层上,如果在添加事件
    var redLayer = CALayer()
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        redLayer.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        redLayer.backgroundColor = UIColor.red.cgColor
        self.view.layer.addSublayer(redLayer)
    }
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let t = touch as! UITouch
            //获取点击的点在self.view坐标中的坐标点
            let touchPoint = t.location(in: self.view)
            //方式一
            //将像素point从self.view.layer中转换到当前视图redLayer中，返回在当前视图中的位置
            let point = redLayer.convert(touchPoint, from: self.view.layer)
            if redLayer.contains(point) {
                NSLog("点击了红色区域")
            }
            //方式二: hitTest方法返回点击点所在的图层本身或者包含这个坐标点的叶子节点图层
            let layer = self.view.layer.hitTest(touchPoint)
            if layer == redLayer {
                NSLog("点击了红色区域")
            }
        }
    }
        
### 5.自动布局
#### 如果想随意控制CALayer的布局,需要手动操作,最简单的方法就是使用CALayerDelegate如下函数:layoutSublayers(of layer: CALayer),当图层的bounds改变活着图层的setNeedLayout方法被调用时,这个函数会被执行,此时我们可以手动重新摆放活着调整子图层的大小,但是不能像UIView的autoresizingMask和constraints属性做到自适应屏幕旋转,这也是用视图而不是图层来构建应用程序的另一个重要原因

### 五.视觉效果
#### 1.视觉效果基本设置
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let redLayer = CALayer()
        redLayer.frame = CGRect(x: 100, y: 100, width: 100, height: 100)
        redLayer.backgroundColor = UIColor.red.cgColor
        self.view.layer.addSublayer(redLayer)
        //1.设置圆角
        redLayer.cornerRadius = 10
        //2.设置边框宽度
        redLayer.borderWidth = 3
        //3.设置边框的颜色(不设置默认的边框颜色是黑色)
        redLayer.borderColor = UIColor.blue.cgColor
        //4.设置阴影
        redLayer.shadowColor = UIColor.black.cgColor //设置阴影的颜色
        //默认是0,范围0-1,0:不可见 1:完全不透明
        redLayer.shadowOpacity = 1
        //CGSize:宽度控制阴影横向的位移,高度控制纵向的位移,默认是(0,-3),即阴影相对于  
        Y轴有3个点的向上位移苹果倾向于阴影是垂直向下的,所以iOS一般把宽度设为0,高度设一个正值
        redLayer.shadowOffset = CGSize(width: 0, height: 3)
        //控制阴影的模糊度,当值为0时,阴影和视图一样有一个明确的边界线,值越大,边界线越模糊,图层的深度就越明显
        redLayer.shadowRadius = 30
            
        //5.裁剪掉超出边界的部分,这里如果设置了阴影的话,同时设置裁剪,是会将阴影裁剪掉的,如果不想阴影  
        被裁剪掉,需用到两个图层,一个只画阴影的空的外图层,一个用masksToBounds裁剪内容的内图层
        redLayer.masksToBounds = true
        
        //6.通过指定阴影的路径来设置阴影
        let squarePath = CGPath(rect: redLayer.bounds, transform: nil)
        redLayer.shadowPath = squarePath
    }

### 2. 图层的蒙板
#### CALayer有一个mask属性,该属性定义了父图层的部分可见区域, 这个属性本身就是个CALayer类型,和其它图层一样具备绘制和布局属性,mask图层的color属性无关紧要的,重要的是图层的轮廓,mask属性作用就是将mask图层实心的部分保留下来,其它的则会被抛弃,如果mask图层比父图层小,则只有在mask图层里面的内容才是它关系的,其它的都会被隐藏起来
    //这里只是说明用法,图层遮罩可以用来做复杂的类似放大镜的效果
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        //放置图片,铺满全屏幕
        let bigLayer = CALayer()
        bigLayer.contents = UIImage(named: "car")?.cgImage
        bigLayer.frame = self.view.bounds
        self.view.layer.addSublayer(bigLayer)
        //创建新的图层
        let imgLayer = CALayer()
        imgLayer.backgroundColor = UIColor.blue.cgColor
        imgLayer.frame = CGRect(x: 100, y: 100, width: 200, height: 100)
        //将新的图层设置为图片的遮罩,这样就会只显示imgLayer尺寸的图片了
        bigLayer.mask = imgLayer
    }
#### 3. 拉伸过滤
#### 当图片需要显示不同的大小的时候,有一种叫做拉伸过滤的算法就起到作用了,它作用于原图的像素上并根据需要生成新的像素显示在屏幕上,CALayer提供了三种拉伸过滤方法,详细的后续再研究
    //CALayer提供了三种拉伸过滤器
    bigLayer.magnificationFilter = CALayerContentsFilter.linear
    bigLayer.magnificationFilter = CALayerContentsFilter.trilinear
    bigLayer.magnificationFilter = CALayerContentsFilter.trilinear
        
#### 4.组透明
#### UIView有alpha属性来确定视图的透明度,CALayer对应也有个opacity属性,两个属性都是影响子层级的, 当视图中存在子控件事,如果设置视图的透明度,那么里面子控件会和视图显示的有些不搭,所以可以设置视图图层的shouldRasterize属性为true,这里同时要设置rasterizationScale属性去匹配屏幕,放置出现Retina屏幕像素化的问题
