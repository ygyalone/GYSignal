# GYSignal

GYSignal是iOS平台下对响应式编程的支持,文档补充中...

## Example

**kvo(观察者模式，信号绑定):**

```objc
[self gy_signalForKeyPath:@"aString"];
GYObserve(self, aString);//宏的便利写法
```

**map(值映射):**

```objc
[signal map:^id(id value) {
    return @"newValue";
}];
```

**flattenMap(平铺映射，返回信号的信号):**

```objc
//not implemented
```

**final(当error或者complete之后执行):**

```objc
//not implemented
```

**diffrent(当value值与上一次触发不同时才触发新的value回调):**

```objc
[signal diffrent];
```

**skip(指定值忽略次数):**

```objc
[signal skip:1];
```

**then(当原信号执行完毕才会订阅下一个信号):**

```objc
[signal1 then:signal2];
```

**zip(信号打包):**

```objc
[signal1 zip:@[signal2]];
```

**zipWith(信号打包):**

```objc
[signal1 zipWith:signal2]
```

**mergeWith(信号组合):**

```objc
[signal1 mergeWith:signal2];
```

**UITextField对text属性的kvo支持:**

```objc
textField.gy_textSignal;
```


## Author

ygyalone, yangguangyu@xunlei.com

## License

GYSignal is available under the MIT license. See the LICENSE file for more info.
