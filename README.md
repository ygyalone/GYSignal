
# GYSignal
**GYSignal是iOS平台下对响应式编程的支持,文档补充中...**

响应式编程框架将异步事件抽象成三类：

- 值事件，可以触发多次
- 错误事件，最多只会触发一次，与完成事件互斥
- 完成事件，最多只会触发一次，与错误事件互斥




## 什么是响应式编程
响应式编程是处理**异步事件**（异步事件就是未来有可能发生的事件，比如数据模型的变化，网络请求响应，手势事件等等）的**编程范式**。编程范式是指编程的方法论，或者说是一个编程的套路。按照这个套路编程，能够写出处理异步事件更好的代码。



## 响应式编程的好处
### 代码逻辑更加集中

使用响应式编程工具可以使分散的业务逻辑集中起来，提高代码的可读性，可维护性。

### 方便实现数据绑定

有A,B,C三个商品订单页面，这三个页面的UI展示和业务流程都依赖一个订单模型。假如在这三个页面中，都可以修改这个订单模型的购买数量属性，由于购买数量属性的修改会影响到这三个页面，所以需要在每一处修改数量属性的地方都通知到其它界面。这样看来，需要在每个修改属性的地方都要加上通知的代码，这样代码不仅冗余（因为每个修改的地方你都要写重复的通知代码），还会耦合到其它页面。

事实上这三个页面只关心这笔订单的各种属性状态，并不关心这些属性在哪里被修改。换句话说，就是这三个页面只需要响应这笔订单属性的变化。我认为这就是响应式编程的思想。

那么在iOS中，怎么监听数据变化，实现对数据模型的绑定呢？KVO了解一下。但是使用KVO代码量会比较多，并且代码可读性较差，还需要考虑移除观察者的时机。种种限制看来，KVO虽然也可以实现数据绑定，但也不是一个很好的方案。如果使用响应式编程框架，则可以用很少的代码实现数据绑定的操作。事实上框架内部对数据绑定的实现也是使用KVO。

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
### 方便异步事件组合

某些异步事件之间可能存在依赖关系，比如有A，B，C三个网络请求，C请求需要在A，B都完成之后才能发起，A和B可以同时执行。正常情况下我们怎么来做呢？可以使用一些状态变量来保存这几个请求的执行状态。或者使用一些线程调度的方法来实现，比如dispatch_group等。但是这些做法可能和具体业务关联，并不通用。

得益于响应式编程对异步事件的抽象，使得我们可以很容易将这些异步事件自由组合起来。

**代码举例:**

```objc
[[[requestA zip:@[requestB]] flattenMap:^GYSignal *(GYTuple *value) {
    return requestC;
}] subscribeValue:^(id value) {
    NSLog(@"value=%@",value);
}];
```



## 类说明

**GYSignal（信号）**

**GYSubscriber（订阅者）**

**GYSignalDisposer（信号销毁者）**

**GYTuple（元组）**



## 基本使用
创建信号

```objc
GYSignal *signal = [GYSignal signalWithAction:^GYSignalDisposer * _Nonnull(id<GYSubscriber>  _Nonnull subscriber) {
    //发送值事件
    [subscriber sendValue:@"1"];
    //发送完成事件
    [subscriber sendComplete];
    //发送错误事件
    [subscriber sendError:[NSError errorWithDomain:@"error domain" code:-1 userInfo:nil]];
    return [GYSignalDisposer disposerWithAction:^{
        //信号销毁之后的操作可以放在这里，例如资源释放等等
    }];
}];
```

订阅信号

```objc
[signal subscribeValue:^(id  _Nullable value) {
        //值事件触发
    } error:^(NSError * _Nonnull error) {
        //错误事件触发
    } complete:^{
        //完成事件触发
}];
```

销毁信号

```objc
GYSignalDisposer *disposer = [signal subscribeValue:^(id  _Nullable value) {
    //值事件触发
}];

//当不再需要订阅信号时，可以手动（非必须，订阅者释放时会自动执行销毁操作）调用销毁方法，执行销毁操作。
[disposer dispose];
```



## 关于内存管理
关于内存引用关系：

待补充...

关于内存泄漏：
由于闭包是引用类型，同时响应式编程很多操作都是放在闭包里面，所以很容易产生循环引用，导致内存泄漏的问题。在OC中可以使用**weak**, **assign**, **unsafe_unretained**来打破循环引用。在Swift中可以通过在闭包的**值引用列表**中表明引用关系**weak**或者**unowned**来打破循环引用。




## 关于Swift
注意：因为数据绑定内部实现使用了OC的runtime和KVO。所以在Swift中数据绑定操作只能作用于NSObject的子类。



## 信号操作

信号类提供了一些基础业务的抽象方法。



**just（固定值信号）**

```objc
GYSignal *signal = [GYSignal just:@"666"];
```

订阅者订阅该信号会收到一次固定的值。



**filter（值过滤）**

* 值回调：当源信号发送值，只有block返回布尔真时订阅者才会触发值回调。
* 错误回调：当源信号发送错误，订阅者会触发错误回调。
* 完成回调：当源信号发送完成，订阅者会触发完成回调。

```objc
[signal filter:^BOOL(NSNumber * _Nullable value) {
    //过滤掉偶数值
    return value.integerValue %2 != 0;
}];
```



**diffrent（值变化）**

- 值回调：当源信号发送值，只有和上一次的值不同时订阅者才会触发值回调。
- 错误回调：当源信号发送错误，订阅者会触发错误回调。
- 完成回调：当源信号发送完成，订阅者会触发完成回调。

```objc
[signal diffrent];
```



**take（节流）**

- 值回调：当源信号发送值，只有 `takeCount` 参数指定的前几个值才会触发订阅者的值回调。
- 错误回调：当源信号发送错误，订阅者会触发错误回调。
- 完成回调：当源信号发送完成，订阅者会触发完成回调。

```objc
//订阅者只会收到信号发送的前3次值
[signal take:3];
```



**skip（值忽略）**

- 值回调：当源信号发送值，只有超过 `skipCount` 参数指定的次数才会触发订阅者的值回调。
- 错误回调：当源信号发送错误，订阅者会触发错误回调。
- 完成回调：当源信号发送完成，订阅者会触发完成回调。

```objc
//订阅者会忽略信号发送的前3次值
[signal skip:3];
```



**retry（失败重试）**

- 值回调：当源信号发送值，订阅者会触发值回调。
- 错误回调：当源信号发送错误，如果失败次数没有超过重试参数指定的次数，会重新订阅源信号。否则触发订阅者错误回调。
- 完成回调：当源信号发送完成，订阅者会触发完成回调。

```objc
//订阅者会忽略信号发送的前3次值
[signal skip:3];
```



**finally（最终操作）**

- 值回调：当源信号发送值，订阅者会触发值回调。
- 错误回调：当源信号发送错误，订阅者会触发错误回调，然后执行最终操作。
- 完成回调：当源信号发送完成，订阅者会触发完成回调，然后执行最终操作。

```objc
[signal finally:^{
    //当触发完成回调或者错误回调后执行
}];
```



**map（值映射）**

* 值回调：当源信号发送值，订阅者会触发值回调，接收到的值为转换之后的值。
* 错误回调：当源信号发送错误，订阅者会触发错误回调。
* 完成回调：当源信号发送完成，订阅者会触发完成回调。

```objc
[signal map:^id _Nullable(id  _Nullable value) {
    return @"new value";
}];
```



**flattenMap（信号映射）**

* 值回调：当源信号发送值，订阅者会去订阅转换后的信号。
* 错误回调：当源信号或者转换后的信号发送错误，订阅者会触发错误回调。
* 完成回调：当源信号或者转换后的信号发送完成，订阅者会触发完成回调。

```objc
[signal flattenMap:^GYSignal *(id value) {
    return innerSignal;
}];
```



**then（后续信号）**

* 值回调：当源信号发送值，订阅者**不会**触发值回调。
* 错误回调：当源信号发送错误，订阅者会触发错误回调。
* 完成回调：当源信号发送完成，订阅者会去订阅参数指定的信号。

```objc
[signal1 then:signal2];
```



**merge（信号合并）**

- 值回调：源信号或者合并的信号发送值，订阅者会触发值回调。
- 错误回调：源信号或者合并的信号发送错误，订阅者会触发错误回调。
- 完成回调：源信号或者合并的信号发送完成，订阅者会触发完成回调。

```objc
[signal1 merge:@[signal2, signal3]];
```



**zip（信号打包）**

* 值回调：只有打包的信号都至少发送过一次值，订阅者才会触发值回调，每个信号的值通过打包顺序从元组对象中获取。
* 错误回调：只要有打包信号发送错误，订阅者会触发错误回调。
* 完成回调：当所有打包的信号都发送完成，订阅者才会触发完成回调。

```objc
[signal1 zip:@[signal2]];
```



### 扩展部分

**gy_signalForKeyPath（监听属性变化）**

`gy_signalForKeyPath` 是 `NSObject` 的扩展方法，该方法将 `KVO` 封装为一个信号。

```objc
GYObserve(self, aString);//宏的便利写法
[self gy_signalForKeyPath:@"aString"];
```



**UITextField.gy_textSignal（监听UITextField的text属性变化）**

当手动输入`UITextField` 控件的内容时，通过 `KVO` 并不能监听到 `text` 属性的变化，而需要通过 `target-action` 的方式获取变化。`gy_textSignal`是 `UITextField` 的扩展方法，通过将 `KVO` 和 `target-action` 统一封装成一个信号，保证在任何时候都能监听 `text` 属性的变化。

```objc
textField.gy_textSignal;
```



## 其它

### 泛型

`GYSignal`支持泛型，泛型类型被用来指定值的类型。推荐使用者在创建信号时指定泛型类型。使用泛型可以减少类型转换的代码，同时也增加了代码的可读性。

```objc
GYSignal<NSNumber *> *signal;
```

###  宏

如果使用 Objective-C 语言调用 `gy_signalForKeyPath` 方法。推荐使用 `GYObserve` 宏。使用该宏除了有智能提示还能够提供编译期的检查，防止 `KeyPath` 写错的问题。

```objc
GYObserve(self, aString);
```

为了防止循环引用导致的内存泄漏，我们经常要对对象进行weak或者strong操作，工具提供了便利宏进行此类操作。

```objc
GYWeak(self)
[GYObserve(self, num) subscribeValue:^(id  _Nullable value) {
    GYStrong(self)
    self.label.text = [value description];
}];
```

### 双向绑定

有时我们希望视图的内容和数据模型绑定，同时数据模型的内容也和视图绑定，这就是双向绑定了。

但是双向绑定会导致一个触发循环的问题，因为视图的变化会触发数据模型的变化，反过来数据模型的变化会触发视图的变化，构成了一个死循环。

目前解决这个问题的方法是打破这个循环：当我们订阅信号时使用 `diffrent` 操作包装成新的信号。因为只有不同的值才会触发值回调，因此打破了双向绑定的触发循环。

```objc
//其实只要有一个信号被 diffrent 即可
[[GYObserve(self, num) diffrent] subscribeValue:^(id  _Nullable value) {
    textField.text = [value description];
}];
    
[[textField.gy_textSignal diffrent] subscribeValue:^(NSString * _Nullable value) {
    self.num = [value integerValue];
}];
```



## Author

ygy

ygy9916730@163.com



## License

GYSignal is available under the MIT license. See the LICENSE file for more info.

