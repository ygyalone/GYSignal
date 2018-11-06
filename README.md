<font face="arial">
# GYSignal
GYSignal是iOS平台下对响应式编程的支持,文档补充中...


## 什么是响应式编程
响应式编程是处理**异步事件**（我认为异步事件就是未来有可能发生的事件，比如数据模型属性值的变化，网络请求响应，手势事件等等）的**编程范式**。编程范式是指编程的方法论，或者说是一个编程的套路。按照这个套路编程，能够写出处理异步事件更好的代码。

## 响应式编程的好处
### 方便实现数据绑定
有A,B,C三个商品订单页面，这三个页面的UI展示和业务流程都依赖一个订单模型。假如在这三个页面中，都可以修改这个订单模型的购买数量属性，由于购买数量属性的修改会影响到这三个页面，所以需要在每一处修改数量属性的地方都通知到其它界面。这样看来，需要在每个修改属性的地方都要加上通知的代码，这样代码不仅冗余（因为每个修改的地方你都要写重复的通知代码），还会耦合到其它页面。</br>
事实上这三个页面只关心这笔订单的各种属性状态，并不关心这些属性在哪里被修改。换句话说，就是这三个页面只需要响应这笔订单属性的变化。我认为这就是响应式编程的思想。</br>
那么在iOS中，怎么监听数据变化，实现对数据模型的绑定呢？KVO了解一下。但是使用KVO代码量会比较多，并且代码可读性较差，还需要考虑移除观察者的时机。种种限制看来，KVO虽然也可以实现数据绑定，但也不是一个很好的方案。如果使用响应式编程框架，则可以用很少的代码实现数据绑定的操作。事实上框架内部对数据绑定的实现也是使用KVO。</br>

**代码举例:**

```objc
//监听order的purchaseNum属性
[[order gy_signalForKeyPath:@"purchaseNum"] subscribeValue:^(id value) {
    NSLog(@"value=%@",value);
}];

//OC中宏的便利写法
[GYObserve(order, purchaseNum) subscribeValue:^(id value) {
    NSLog(@"value=%@",value);
}];
```
<br/>

### 方便异步事件组合
某些异步事件之间可能存在依赖关系，比如有A，B，C三个网络请求，C请求需要在A，B都完成之后才能发起，A和B可以同时执行。正常情况下我们怎么来做呢？可以使用一些状态变量来保存这几个请求的执行状态。或者使用一些线程调度的方法来实现，比如dispatch_group等。但是这些做法可能和具体业务关联，并不通用。</br>
得益于响应式编程对异步事件的抽象，使得我们可以很容易将这些异步事件自由组合起来。</br>

**代码举例:**

```objc
[[[requestA zip:@[requestB]] flattenMap:^GYSignal *(GYTuple *value) {
    return requestC;
}] subscribeValue:^(id value) {
    NSLog(@"value=%@",value);
}];
```
</br>

## 类说明
**GYSigna(信号)**

**GYSubscriber(信号订阅者)**

**GYSignalDisposer(信号销毁者)**

**GYTuple(元组)**
</br>

## 基本使用
待补充...

## 关于内存管理
关于内存引用关系:</br> 待补充...</br>

关于内存泄漏:</br>
由于闭包是引用类型，同时响应式编程很多操作都是放在闭包里面，所以很容易产生循环引用，导致内存泄漏问题。当然，没有循环引用是不需要考虑这个问题的。</br>
在OC中可以使用**weak**, **assign**, **unsafe_unretained**来解除循环引用链。</br>
在Swift中可以通过在闭包的**值引用列表**中表明引用关系**weak**，**unowned**来解除循环引用链表。


## 关于Swift
注意：数据绑定操作只能是NSObject的子类，因为数据绑定用到了OC的runtime方法。

## 信号操作

**map(值映射):**

> OnValue:当原信号发送值时，订阅者会收到映射之后的值。</br>
> OnError:当原信号发送失败时，订阅者会收到失败。</br>
> OnComplete:当原信号发送完成时，订阅者会收到完成。

```objc
[signal map:^id(id value) {
    return @"newValue";
}];
```
</br>

**flattenMap(平铺映射，返回信号的信号):**

> OnValue:当原信号发送值时，订阅者会去订阅信号映射返回的信号。</br>
> OnError:当原信号发送失败时，订阅者会收到失败。</br>
> OnComplete:当原信号发送完成时，订阅者会收到完成。

```objc
[signal flattenMap:^GYSignal *(id value) {
    return innerSignal;
}];
```
</br>

**finally(当error或者complete之后执行):**

> OnValue:当原信号发送值时，订阅者会收到值。</br>
> OnError:当原信号发送失败时，订阅者会收到失败，接着执行最终操作。</br>
> OnComplete:当原信号发送完成时，订阅者会收到完成，接着执行最终操作。

```objc
[signal finally:^{
    //on finally
}];
```
</br>

**diffrent(当value值与上一次触发不同时才触发新的value回调):**

> OnValue:当原信号发送的值和上次不同时，订阅者才会收到值。</br>
> OnError:当原信号发送失败时，订阅者会收到失败。</br>
> OnComplete:当原信号发送完成时，订阅者会收到完成。

```objc
[signal diffrent];
```
</br>

**skip(指定值忽略次数):**

> OnValue:当原信号发送的值超过忽略次数后，订阅者才会收到值。</br>
> OnError:当原信号发送失败时，订阅者会收到失败。</br>
> OnComplete:当原信号发送完成时，订阅者会收到完成。

```objc
[signal skip:1];
```
<br/>

**then(当原信号执行完毕才会订阅下一个信号):**

> OnValue:当原信号发送值时，订阅者不会收到值。</br>
> OnError:当原信号发送失败时，订阅者会收到失败。</br>
> OnComplete:当原信号发送完成时，订阅者会去订阅后续信号。

```objc
[signal1 then:signal2];
```
<br/>

**zip(信号打包):**

> OnValue:只有打包的信号中都至少发送过一次值，新的信号才会发送值，并且订阅者收到的值是一个元组对象，可以根据打包时的顺序在元组中取值。</br>
> OnError:只要有一个打包的信号发送失败，这个新的信号就会发送失败。</br>
> OnComplete:当所有打包的信号都发送完成时，这个新的信号才会发送完成。

```objc
[signal1 zip:@[signal2]];
```
<br/>

**merge(信号组合):**

> OnValue:当组合的信号发送值时，订阅者会收到值。</br>
> OnError:当组合的信号发送失败时，订阅者会收到失败。</br>
> OnComplete:当组合的信号发送完成时，订阅者会收到完成。

```objc
[signal1 merge:@[signal2, signal3]];
```
<br/>

**kvo(观察者模式，信号绑定):**

```objc
[self gy_signalForKeyPath:@"aString"];
GYObserve(self, aString);//宏的便利写法
```
<br/>

**UITextField对text属性的kvo支持:**

```objc
textField.gy_textSignal;
```
<br/>

## 补充
GYSignal是怎么产生的呢？因为我之前使用过ReactiveCocoa(iOS平台下的一个响应式编程框架)，当然是模仿的咯，哈哈..

## Author

ygyalone, yangguangyu@xunlei.com

## License

GYSignal is available under the MIT license. See the LICENSE file for more info.
</font>