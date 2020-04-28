##  响应链及事件传递
### 我们思考一个问题：当我们点击屏幕触发事件的时候，该事件是如何传递和响应的？首先我们需要确定我们点击的是哪个视图吧？即找到第一响应者；然后我们还得确定这个视图能不能响应事件吧，如果不能响应我们怎么办？需要注意的是iOS中只有继承自UIResponder的子类才能够接收和处理事件，我们把这些对象称为响应者对象；所以这里我们需要解释两个问题
* 点击屏幕之后，如何找到第一响应者？
* 找到第一响应者之后，如果第一响应者没有处理事件，那么事件该如何传递




### 1. 如何寻找第一响应者？
#### 当我们点击屏幕的时候，UIKit会生成UIEvent对象来描述触摸事件(包含触碰坐标等信息)，并将该对象放入AppDelegate的事件队列中，AppDelegate会从事件队列中取出触摸事件传递给UIWindow来处理，UIWindow 会通过hitTest:withEvent:方法寻找触碰点所在的视图，找到第一响应者，这个过程称之为hit-test view。首先我们需要先了解UIIVew分类中的两个重要方法
    //去寻找最适合的View，返回第一响应者，即触碰点的视图
    -(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
    // 用来判断某一个点击的位置是否在视图范围内，如果在就返回YES
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
