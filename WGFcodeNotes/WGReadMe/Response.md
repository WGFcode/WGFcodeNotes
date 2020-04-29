##  响应链及事件传递 & 手势
### 我们思考一个问题：当我们点击屏幕触发事件的时候，该事件是如何传递和响应的？首先我们需要确定我们点击的是哪个视图吧？即找到第一响应者；然后我们还得确定这个视图能不能响应事件吧，如果不能响应我们怎么办？需要注意的是iOS中只有继承自UIResponder的子类才能够接收和处理事件，我们把这些对象称为响应者对象；所以这里我们需要解释两个问题
* 点击屏幕之后，如何找到第一响应者？
* 找到第一响应者之后，如果第一响应者没有处理事件，那么事件该如何传递




### 1. 如何寻找第一响应者？
#### 当我们点击屏幕的时候，UIKit会生成UIEvent对象来描述触摸事件(包含触碰坐标等信息)，并将该对象放入AppDelegate的事件队列中，AppDelegate会从事件队列中取出触摸事件传递给UIWindow来处理，UIWindow 会通过hitTest:withEvent:方法寻找触碰点所在的视图，找到第一响应者，这个过程称之为hit-test view。首先我们需要先了解UIIVew分类中的两个重要方法
    //去寻找最适合的View，返回第一响应者，即触碰点的视图
    -(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
    // 用来判断某一个点击的位置是否在视图范围内，如果在就返回YES,继续遍历该视图的子视图；如果返回NO，则不再遍历它的子视图；
    - (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event


#### 1.1 hit-test view寻找第一响应者过程（假如我们点击了UIWindow->A2->B2）
                     UIWindow
            A1          A2        A3
          C1  c2     B1 B2 B3     D1

* UIWindow首先调用hitTest方法，然后再调用pointInside方法，如果pointInside方法返回YES表示触摸点在UIWindow上
* 遍历UIWindow下的子视图A1，A2......
* 调用A1的hitTest方法，然后再判断A1的pointInside方法，如果pointInside方法返回NO，表示触摸点不再当前视图A1上，则hitTest方法返回nil，即使A1视图还有子视图，也不会再去遍历了
* 然后调用A2的hitTest方法，再判断A2的pointInside方法，如果返回YES，表示触碰点在当前的A2视图上，然后再遍历A2视图的子视图B1，B2，B3
* 调用B1的hitTest方法，再判断B1的pointInside方法，如果返回NO，表示触碰点不在当前的B1视图上，则hitTest方法返回nil，即使B1视图还有子视图，也不会再去遍历了
* 然后调用B2的hitTest方法，再判断B2的pointInside方法，如果返回YES，表示触碰点在B2的视图上，因为B2没有子视图了，所以hitTest方法就将B2返回了-->接着A2的hitTest方法也返回了B2-->接着UIWindow的hitTest也返回了B2
* 至此我们找到了最佳响应者或者称之为第一响应者
#### 结论:
1. 寻找事件的最佳响应视图是通过对视图调用hitTest和pointInside完成的
2. hitTest的调用顺序是从UIWindow开始，对视图的每个子视图依次调用，子视图的调用顺序是从后面往前面，也可以说是从显示最上面到最下面
3. 遍历直到找到响应视图，然后逐级返回最终到UIWindow返回此视图


### 1.2 哪些情况下，hiTest不会被视图调用？
#### 下面四种情况会导致hiTest不会被调用，如果出现视图无法响应事件，也可以通过下面来排查原因
* 视图的Alpha=0
* 子视图超出父视图的情况
* userInteractionEnabled=NO
* hidden=YES

### 2. 第一响应者如何处理事件
#### UIResponder主要提供了4中方法来处理触摸事件，分别对应触摸事件的开始、移动、结束、取消，如果需要自定义事件，可以重写这些方法来实现；如果第一响应者没有处理事件，那么事件就会被传递，UIResponder都有一个nextResponder属性，这个属性会返回下一个事件处理者，如果响应链中的每个响应者都没有处理事件，那么事件就会被丢弃，我们借用1.1中的例子来解释具体流程
        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
        -(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
        -(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
        -(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
* UIWindow通过hitTest方法找到并返回了最佳响应者(第一响应者) B2
* 如果B2实现了触摸事件,那么直接调用触摸事件即可
* 如果B2没有实现触摸事件 ，那么调用B2的nextResponder方法找到下一个响应者A2
* 如果A2实现了触摸事件，那么直接调用即可；如果没有实现，则调用A2的nextResponder方法找到下一个响应者
* 如果一直找到UIWindow也没有实现触摸事件，那么就会调用AppDelegate，判断AppDelegate是否实现了触碰事件，如果没有实现，那么这个触碰事件就会被抛弃
#### 总结:
1. 找到最适合的响应视图后事件会从此视图开始沿着响应链nextResponder传递，直到找到处理事件的视图,如果没有处理的事件会被丢弃。
2. 如果视图有父视图则nextResponder指向父视图，如果是根视图则指向控制器，最终指向AppDelegate, 他们都是通过重写nextResponder来实现。

### 3.案例演示
#### 3.1 我们在视图WGMainObjcVC的View上添加WGView子视图，又在WGView上添加了子视图WGView1，在控制器和这两个子视图上都实现touchesBegan方法，如下：
        @implementation WGView
        -(instancetype)initWithFrame:(CGRect)frame {
            if (self = [super initWithFrame:frame]) {
                self.backgroundColor = [UIColor redColor];
            }
            return self;
        }
        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            NSLog(@"WGView点击了");
        }
        @end

        @implementation WGView1
        -(instancetype)initWithFrame:(CGRect)frame {
            if (self = [super initWithFrame:frame]) {
                self.backgroundColor = [UIColor yellowColor];
            }
            return self;
        }
        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            NSLog(@"WGView1点击了");
        }
        @end

        @implementation WGMainObjcVC
        - (void)viewDidLoad {
            [super viewDidLoad];
            self.view.backgroundColor = [UIColor whiteColor];
            WGView *view = [[WGView alloc]initWithFrame:CGRectMake(0, 100, 300, 200)];
            [self.view addSubview:view];
            
            WGView1 *view1 = [[WGView1 alloc]initWithFrame:CGRectMake(50, 150, 150, 80)];
            [view addSubview:view1];
        }

        -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            NSLog(@"WGMainObjcVC.view触摸事件响应了");
        }
        @end
        
        打印结果:  WGView1点击了   (点击WGView1的区域)
#### 思考:WGView1是WGView的子视图，为什么WGView的touchesBegan方法没有执行？因为子视图WGView1已经实现了触摸事件，所以不会再向它的下一个响应者(父视图WGView)传递触摸事件了；如果想传递的话，在子视图WGView1的touchesBegan方法里面调用[super touchesBegan]的方法,那么当WGView1子视图处理触摸事件前会先调用父视图(WGView)的touchesBegan方法，然后处理自己的事件，如下
        @implementation WGView1
        -(instancetype)initWithFrame:(CGRect)frame {
            if (self = [super initWithFrame:frame]) {
                self.backgroundColor = [UIColor yellowColor];
            }
            return self;
        }
        - (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
            [super touchesBegan:touches withEvent:event];
            NSLog(@"WGView1点击了");
        }
        @end
        
        打印结果: WGView点击了    (点击WGView1的区域)
                WGView1点击了 
#### 如果WGView1视图没有处理触摸事件，即没有重写touchesBegan方法情况下，当点击WGView1区域时，最佳响应者是WGView1，但是WGView1没有实现触摸事件的能力，那么就会通过WGView1的nextResponder寻找下一个响应者(即父视图WGView)，如果WGView实现了触摸事件，那么就终止寻找下一个响应者。

#### 如果两个子视图和控制器都实现了touchesBegan方法，那么如果点击WGView1区域，我只想让父视图WGView响应事件，那么该如何做那？
1. 我们可以在WGView1视图上重写pointInside方法并设置该方法返回NO，意思就是设置触摸点不再WGView1视图上。那么WGView1视图上对应的hitTest方法就会返回nil,然后回到父视图WGView的判断中并且对应的hitTest方法会返回WGView视图本身作为第一响应者，这样WGView1的父视图WGView就可以响应事件了
2. 除了设置pointInside方法为NO外，我们也可以在WGView1视图中重写hitTest并返回self.superview。意思就是直接设置第一响应者为WGView1的父视图
3. 除了上面两种方式外，我们更简单一点就是设置WGView1的setUserInteractionEnabled:为NO，即不让视图WGView1具备交互能力

## 手势
### 4.1 iOS开发中用户交互一般都是通过手势来识别并处理的，手势UIGestureRecognizer是继承自NSObject的，我们先了解下手势API

        初试化一个手势对象，并且设置响应对象和响应事件
        - (instancetype)initWithTarget:(nullable id)target action:(nullable SEL)action;
        没有绑定事件的初始化方法
        - (instancetype)init;
        - (nullable instancetype)initWithCoder:(NSCoder *)coder;

        为手势添加响应者和响应事件
        - (void)addTarget:(id)target action:(SEL)action;
         
        移除指定响应者的响应事件
        - (void)removeTarget:(nullable id)target action:(nullable SEL)action;
         
        当前手势的状态
        @property(nonatomic,readonly) UIGestureRecognizerState state;
         
        手势的代理
        @property(nullable,nonatomic,weak) id <UIGestureRecognizerDelegate> delegate;
         
        是否启用手势识别，默认是YES，如果设置为NO，则表示不能识别手势，如果有正在识别的手势，则也会被取消
        @property(nonatomic, getter=isEnabled) BOOL enabled;
         
        点击屏幕次数 只读
        @property(nonatomic, readonly) NSUInteger numberOfTouches;

        ios(11.0)手势名称，主要用来调试
        @property (nullable, nonatomic, copy) NSString *name;

        手势添加到的视图，一般通过addGestureRecognizer:方法来设置
        @property(nullable, nonatomic,readonly) UIView *view;
         
        默认是YES，设置为YES时，当手势识别器识别到touch后，会发送touchesCancelled:或pressesCancelled:方法
        给hit-testView来取消hit-testView对touch的响应，这个时候只有手势识别器可以响应touch，即触摸事件不会被触发
        当设置为NO时，当手势识别器识别到touch后，不会再发送touchesCancelled:和pressesCancelled:方法给hit-testView，
        即手势识别器和hit-testView都会响应touch
        @property(nonatomic) BOOL cancelsTouchesInView;
         
        默认是NO，设置为NO时，当发生一个touch时，手势识别器先捕获到touch,然后再发送给hit-testview，两者各自作出响应
        设置为YES时，手势识别器在识别touch的过程中，不会再发送touch给hit-testview，即hit-testview不会有任何触摸事件；
        只有在识别失败之后才会将touch发给hit-testview，这种情况下hit-testview的响应会延迟约0.15ms。
        @property(nonatomic) BOOL delaysTouchesBegan;

        默认是YES，设置为YES时，当发生一个touch时，在手势识别成功后，给hit-testview发送touchesEnded:或pressesEnded:消息；如果手势
        识别失败，会延迟大概0.15ms,期间没有接收到别的touch时才会发送touchesEnded:或pressesEnded:
        设置为NO时，则不会延迟，即会立即发送touchesEnded:或pressesEnded:以结束当前触摸。
        @property(nonatomic) BOOL delaysTouchesEnded;

        支持的TouchTypes.
        @property(nonatomic, copy) NSArray<NSNumber *> *allowedTouchTypes;
         
        支持的UIPress属性
        @property(nonatomic, copy) NSArray<NSNumber *> *allowedPressTypes;

        默认是YES，当设置为YES时,如果新的手势和旧的类型不匹配,新手势将会被手势识别器自动忽略.
        当设置为NO时,手势识别器会识别allowedTouchTypes里面支持类型的手势
        @property (nonatomic) BOOL requiresExclusiveTouchType;

        例子 [A requireGestureRecognizerToFail: B] 手势A进行识别和执行的前提是 手势B失败了
        - (void)requireGestureRecognizerToFail:(UIGestureRecognizer *)otherGestureRecognizer;

         获取手指点击屏幕实时的坐标点
        - (CGPoint)locationInView:(nullable UIView*)view;

        返回指定视图中第几个触摸点的坐标系
        - (CGPoint)locationOfTouch:(NSUInteger)touchIndex inView:(nullable UIView*)view;

### 4.1 手势分类
* UITapGestureRecognizer: 点按手势

        @property (nonatomic) NSUInteger  numberOfTapsRequired;  默认是1，设置点击的次数
        @property (nonatomic) NSUInteger  numberOfTouchesRequired;  默认是1，设置手指的个数，即需要几个手指点击        
* UIPinchGestureRecognizer: 捏合手势，
        
        @property (nonatomic) CGFloat scale;                伸缩比例
        @property (nonatomic,readonly) CGFloat velocity;    伸缩速度
* UIRotationGestureRecognizer: 旋转手势

        @property (nonatomic)  CGFloat rotation;                    旋转弧度(角度)
        @property (nonatomic,readonly) CGFloat velocity;      旋转速度(每秒旋转多少弧度)
* UISwipeGestureRecognizer: 轻扫手势

        @property(nonatomic) NSUInteger numberOfTouchesRequired;           需要的轻扫手指数量(默认是1)
        @property(nonatomic) UISwipeGestureRecognizerDirection direction;  轻扫方向，默认是向右
        typedef NS_OPTIONS(NSUInteger, UISwipeGestureRecognizerDirection) {
            UISwipeGestureRecognizerDirectionRight = 1 << 0,  向右
            UISwipeGestureRecognizerDirectionLeft  = 1 << 1,  向左
            UISwipeGestureRecognizerDirectionUp    = 1 << 2,  向上
            UISwipeGestureRecognizerDirectionDown  = 1 << 3   向下
        };
* UIPanGestureRecognizer: 平移手势

        @property (nonatomic) NSUInteger minimumNumberOfTouches; 平移需要的最小的触摸数(手指个数)默认是1
        @property (nonatomic) NSUInteger maximumNumberOfTouches; 平移限制的最大触摸数(手指个数)默认是1
        获取移动后手指在相对坐标系内移动的距离
        - (CGPoint)translationInView:(nullable UIView *)view;
        
        一般在Action内计算偏移量的时候,使用该方法将偏移量置位0(偏移量是一直累加的,不会自动清零)
        - (void)setTranslation:(CGPoint)translation inView:(nullable UIView *)view;
    
        获取在View中的手势的平移速度(每秒几个点)
        - (CGPoint)velocityInView:(nullable UIView *)view;  
* UIScreenEdgePanGestureRecognizer: 屏幕边缘平移，继承自UIPanGestureRecognizer平移手势

        设置起始边缘
        @property (readwrite, nonatomic, assign) UIRectEdge edges; 
        typedef NS_OPTIONS(NSUInteger, UIRectEdge) {
            UIRectEdgeNone   = 0,             没有边缘
            UIRectEdgeTop    = 1 << 0,        矩形顶部
            UIRectEdgeLeft   = 1 << 1,        矩形左边
            UIRectEdgeBottom = 1 << 2,        矩形底部
            UIRectEdgeRight  = 1 << 3,        矩形右边
            UIRectEdgeAll = UIRectEdgeTop | UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight 矩形所有边
        } API_AVAILABLE(ios(7.0));

* UILongPressGestureRecognizer: 长按手势

        @property (nonatomic) NSUInteger numberOfTapsRequired;     要求的点击次数，默认为0次
        @property (nonatomic) NSUInteger numberOfTouchesRequired;  需要的手指数量，默认是1
        @property (nonatomic) NSTimeInterval minimumPressDuration; 最小的按压时间，默认是0.5秒
        @property (nonatomic) CGFloat allowableMovement;           允许识别过程中手指移动的最大距离，默认是10像素

### 4.2 手势代理  UIGestureRecognizerDelegate
        是否允许触发当前手势
        - (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer;

        默认是NO，是否允许两个手势同时识别； 设置YES:可以保证同时识别 设置NO：不能保证不同时识别，因为其他手势代理可能设置为YES
        - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
         
        是否接收触摸手势
        - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;

        是否接收按压手势
        - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press;

        //下面两个方法用来控制手势的互斥执行的
        返回YES，第一个手势和第二个互斥时，第一个会失效
        - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
        返回YES，第一个和第二个互斥时，第二个会失效
        - (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
### 4.3 手势状态 UIGestureRecognizerState
        typedef NS_ENUM(NSInteger, UIGestureRecognizerState) {
            UIGestureRecognizerStatePossible,   默认的状态，这个时候的手势并没有具体的情形状态
            UIGestureRecognizerStateBegan,      手势开始被识别的状态，但尚未改变或者完成时
            UIGestureRecognizerStateChanged,    手势识别发生改变的状态
            UIGestureRecognizerStateEnded,      手势识别完成，将会执行触发的方法
            UIGestureRecognizerStateCancelled,  手势识别取消，恢复到默认状态
            UIGestureRecognizerStateFailed,     识别失败，方法将不会被调用，恢复到默认状态
            UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded
        };
