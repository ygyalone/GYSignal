# GYSignal

GYSignal是iOS平台下对响应式编程的支持,文档补充中...

## Example

**map(值映射):**


> onValue:当原信号发送值时，订阅者会收到映射之后的值。
>
> onError:当原信号发送失败时，订阅者会收到失败。
> 
> onComplete:当原信号发送完成时，订阅者会收到完成。


```objc
[signal map:^id(id value) {
    return @"newValue";
}];
```
<br/>

**flattenMap(平铺映射，返回信号的信号):**

> onValue:当原信号发送值时，订阅者会去订阅信号映射返回的信号。
>
> onError:当原信号发送失败时，订阅者会收到失败。
>
> onComplete:当原信号发送完成时，订阅者会收到完成。

```objc
[signal flattenMap:^GYSignal *(id value) {
    return innerSignal;
}];
```
<br/>

**finally(当error或者complete之后执行):**

> onValue:当原信号发送值时，订阅者会收到值。
>
> onError:当原信号发送失败时，订阅者会收到失败，接着执行最终操作。
>
> onComplete:当原信号发送完成时，订阅者会收到完成，接着执行最终操作。

```objc
[signal finally:^{
    //on finally
}];
```
<br/>

**diffrent(当value值与上一次触发不同时才触发新的value回调):**

> onValue:当原信号发送的值和上次不同时，订阅者才会收到值。
>
> onError:当原信号发送失败时，订阅者会收到失败。
>
> onComplete:当原信号发送完成时，订阅者会收到完成。

```objc
[signal diffrent];
```
<br/>

**skip(指定值忽略次数):**

> onValue:当原信号发送的值超过忽略次数后，订阅者才会收到值。
>
> onError:当原信号发送失败时，订阅者会收到失败。
>
> onComplete:当原信号发送完成时，订阅者会收到完成。

```objc
[signal skip:1];
```
<br/>

**then(当原信号执行完毕才会订阅下一个信号):**

> onValue:当原信号发送值时，订阅者不会收到值。
>
> onError:当原信号发送失败时，订阅者会收到失败。
>
> onComplete:当原信号发送完成时，订阅者会去订阅后续信号。

```objc
[signal1 then:signal2];
```
<br/>

**zip(信号打包):**

> onValue:只有打包的信号中都至少发送过一次值，新的信号才会发送值，并且订阅者收到的值是一个元组对象，可以根据打包时的顺序在元组中取值。
>
> onError:只要有一个打包的信号发送失败，这个新的信号就会发送失败。
>
> onComplete:当所有打包的信号都发送完成时，这个新的信号才会发送完成。

```objc
[signal1 zip:@[signal2]];
```
<br/>

**zipWith(信号打包):**

> 参考zip

```objc
[signal1 zipWith:signal2];
```
<br/>

**merge(信号组合):**

> onValue:当组合的信号发送值时，订阅者会收到值。
>
> onError:当组合的信号发送失败时，订阅者会收到失败。
>
> onComplete:当组合的信号发送完成时，订阅者会收到完成。

```objc
[signal1 merge:@[signal2, signal3]];
```
<br/>

**mergeWith(信号组合):**

> 参考merge

```objc
[signal1 mergeWith:signal2];
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

## Author

ygyalone, yangguangyu@xunlei.com

## License

GYSignal is available under the MIT license. See the LICENSE file for more info.
