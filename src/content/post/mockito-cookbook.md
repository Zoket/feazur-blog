---
title: Mockito Cookbook
description: Mockito的简单使用指南，tranlate from https://www.baeldung.com/mockito-behavior.
tags:
  - Java
  - Unit-test
pubDate: 2024-06-05
draft: false
---
## 前言
对Mockito的很多api感到迷惑，不知道起到什么作用。基于目前基于单元测试开发的想法，需要在开发之前大致了解清楚Mockito常用api的用法，以便于做快速单元测试。

首先Mockito主要作用是模拟一个类的行为，并通过模拟行为对类的调用次数、执行流程做判断。
在使用Mockito之前，需要在测试类中对它做初始化，这里有两种方法：
```
@ExtendWith(MockitoExtension.class)
```
```
@BeforeEach
public void init() {
  MockitoAnnotations.openMocks(this);
}
```
## Mock & Spy
```
@Mock
private List<String> mockList;
----------------------------------------------
List<String> mockList = Mockito.mock(List.class);
```
以上即完成了对List对象的模拟。mockList是模拟出来的对象，它具有List接口具有的所有能力，但是并不真正调用它。
与Mock相对，Spy不是模拟一个对象，而是监听一个真实的对象：
```
@Spy
private List<String> spyList = new ArrayList<>();
--------------------------------------------
List<String> list = new ArrayList<>();
List<String> spyList = Mockito.spy(list);
```
对象被spy之后可以通过when/then之类的方法覆盖原本的方法执行。
```
 List<String> list = new ArrayList<String>();
    List<String> spyList = spy(list);

    assertEquals(0, spyList.size());

    doReturn(100).when(spyList).size();
    assertThat(spyList).hasSize(100);
```

## verify cookbook
```
@Test
public void test() {
  mockList.add("one");
  Mockito.verify(mockList).add("one");
  Assertions.assertEquals(mockList.size(), 0);
}
```
在这段代码中，首先调用了这个虚拟List对象的add()方法添加了一个元素。之后verify(mockList)的意思是“我要对mockList这个对象做一下验证啦！”，那么要做什么验证呢？就是验证它是否调用了add()方法并且添加了`“one”`进去。上面这段代码执行的话可以正常通过测试无事发生，但是如果删除掉第三行，verify方法就会报错`Wanted but not invoked:mockList.add("one");`。或者将第三行add的值改成`"two"`，也会得到一个错误`Argument(s) are different! Wanted:mockList.add("one");Actual invocations have different arguments:mockList.add("two");`。
有意思的是，第五行的断言是正确的，可能对mock对象的调用不会调用被mock的类？所以被mock类的“调用add方法则size返回值加1”这种逻辑不会被执行。
OK，verify的作用总结来说就是“验证交互”。它还有以下用法：
1. 验证交互次数&至少发生一定次数：
```
List<String> mockedList = mock(MyList.class);
mockedList.size();
verify(mockedList, times(1)).size();
--------------------------------------------------------------
List<String> mockedList = mock(MyList.class);
mockedList.clear();
mockedList.clear();
mockedList.clear();

verify(mockedList, atLeast(1)).clear();
verify(mockedList, atMost(10)).clear();
```
2. 验证未与指定mock类发生交互；
```
List<String> mockedList = mock(MyList.class);
verifyNoInteractions(mockedList);
```
3. 验证未与指定方法发生交互；
```
List<String> mockedList = mock(MyList.class);
verify(mockedList, times(0)).size();
```
4. 验证没有意外的交互-这条会失败；
```
List<String> mockedList = mock(MyList.class);
mockedList.size();
mockedList.clear();

verify(mockedList).size();
assertThrows(NoInteractionsWanted.class, () -> verifyNoMoreInteractions(mockedList));
```
5. 验证交互顺序；
```
List<String> mockedList = mock(MyList.class);
mockedList.size();
mockedList.add("a parameter");
mockedList.clear();

InOrder inOrder = Mockito.inOrder(mockedList);
inOrder.verify(mockedList).size();
inOrder.verify(mockedList).add("a parameter");
inOrder.verify(mockedList).clear();
```
6. 验证交互是否未发生；
```
List<String> mockedList = mock(MyList.class);
mockedList.size();

verify(mockedList, never()).clear();
```
7. 验证与确切参数的交互；
```
List<String> mockedList = mock(MyList.class);
mockedList.add("test");

verify(mockedList).add("test");
```
8. 验证与 flexible/any 参数的交互；
```
List<String> mockedList = mock(MyList.class);
mockedList.add("test");

verify(mockedList).add(anyString());
```
9. 使用参数捕获验证交互：
```
List<String> mockedList = mock(MyList.class);
mockedList.addAll(Lists.<String> newArrayList("someElement"));

ArgumentCaptor<List<String>> argumentCaptor = ArgumentCaptor.forClass(List.class);
verify(mockedList).addAll(argumentCaptor.capture());

List<String> capturedArgument = argumentCaptor.getValue();
assertThat(capturedArgument).contains("someElement");
```


## when/then cookbook
先创建一个简单类：
```
public class MyList extends AbstractList<String> {

    @Override
    public String get(final int index) {
        return null;
    }
    @Override
    public int size() {
        return 1;
    }
}
```
然后给mock类配置简单的返回值：
```
MyList listMock = mock(MyList.class);
when(listMock.add(anyString())).thenReturn(false);

boolean added = listMock.add(randomAlphabetic(6));
assertThat(added).isFalse();
```
可以看到when/then的语法很语义化，第二行可以这么读：“当listMock调用add方法并且参数是任意字符串的时候，return false”。
之后的两行就是对配置的这个行为的验证：调用add并随便传入什么东西，然后验证返回值是否是false。
上例还有另一种写法：
```
MyList listMock = mock(MyList.class);
doReturn(false).when(listMock).add(anyString());

boolean added = listMock.add(randomAlphabetic(6));
assertThat(added).isFalse();
```
配置一个方法调用出现的异常：
```
MyList listMock = mock(MyList.class);
when(listMock.add(anyString())).thenThrow(IllegalStateException.class);

assertThrows(IllegalStateException.class, () -> listMock.add(randomAlphabetic(6)));
```
配置具有 void 返回类型的方法的行为 — 抛出异常：
```
MyList listMock = mock(MyList.class);
doThrow(NullPointerException.class).when(listMock).clear();

assertThrows(NullPointerException.class, () -> listMock.clear());
```
配置多个调用的行为：
```
MyList listMock = mock(MyList.class);
when(listMock.add(anyString()))
  .thenReturn(false)
  .thenThrow(IllegalStateException.class);

assertThrows(IllegalStateException.class, () -> {
    listMock.add(randomAlphabetic(6));
    listMock.add(randomAlphabetic(6));
});
```
配置spy的行为：
```
MyList instance = new MyList();
MyList spy = spy(instance);

doThrow(NullPointerException.class).when(spy).size();

assertThrows(NullPointerException.class, () -> spy.size());
```
配置方法以在模拟上调用真实的底层方法：
```
MyList listMock = mock(MyList.class);
when(listMock.size()).thenCallRealMethod();

assertThat(listMock).hasSize(1);
```
使用自定义 Answer 配置模拟方法调用：
```
MyList listMock = mock(MyList.class);
doAnswer(invocation -> "Always the same").when(listMock).get(anyInt());

String element = listMock.get(1);
assertThat(element).isEqualTo("Always the same");
```
这里的answer应该是可以在这个闭包里自定义调用这个方法的逻辑。

## ArgumentCaptor
参数捕获器，直接上例子：
```
@Test
public void whenNotUseCaptorAnnotation_thenCorrect() {
    List mockList = Mockito.mock(List.class);
    ArgumentCaptor<String> arg = ArgumentCaptor.forClass(String.class);

    mockList.add("one");
    Mockito.verify(mockList).add(arg.capture());

    assertEquals("one", arg.getValue());
}
```
可以看到，ArgumentCaptor对象在验证的时候调用可以将原本的参数捕获到。暂时不知道还能用在什么地方，感觉可以用于捕获方法运行中的中间结果并验证。
另外其也可以使用`@Captor`注解创建。

## InjectMocks
InjectMocks可以将mock对象注入到另一个类的属性中：
先来看一个类：
```
public class MyDictionary {
    Map<String, String> wordMap;

    public MyDictionary() {
        wordMap = new HashMap<String, String>();
    }
    public void add(final String word, final String meaning) {
        wordMap.put(word, meaning);
    }
    public String getMeaning(final String word) {
        return wordMap.get(word);
    }
}

```
我们准备注入wordMap这个属性：
```
@Mock
Map<String, String> wordMap;

@InjectMocks
MyDictionary dic = new MyDictionary();

@Test
public void whenUseInjectMocksAnnotation_thenCorrect() {
    Mockito.when(wordMap.get("aWord")).thenReturn("aMeaning");

    assertEquals("aMeaning", dic.getMeaning("aWord"));
}
```
这里可以看到，首先创建一个wordMap的mock对象，然后在MyDictionary对象上加@InjectMocks注解，wordMap就会被注入进去，我们就可以通过控制wordMap的行为改变被注入的类的行为。

