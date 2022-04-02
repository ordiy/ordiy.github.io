---
layout: post
title: Python 使用绘制统计图
date: 2019-11-14 15:29:51
categories:
  - tech
  - python
tags:
  - python
  - python-plot
excerpt: 学习python 绘制基本的折线图、对散点图进行拟合、使用快速傅立叶变换对周期性矩形波(方波)信号记性分解（分解出频率、时域图)
---

# 简介
[Matplotlib is a comprehensive library for creating static, animated, and interactive visualizations in Python. ](https://matplotlib.org/)
`Matplotlib`是常用的数据可视化工具之一(灵活、功能强大)

安装包：
```bash
#url 国内下载速度较慢 可以使用proxychain + 梯
pip install matplotlib
pip install scipy

```

# python 绘图统计

### 折线图
```python
#python3
#coding:utf-8

import matplotlib.pyplot as plt
import matplotlib.font_manager

x1=[20,33,51,79,101,121,132,145,162,182,203,219,232,243,256,270,287,310,325]
y1=[49,48,48,48,48,87,106,123,155,191,233,261,278,284,297,307,341,319,341]
x2=[31,52,73,92,101,112,126,140,153,175,186,196,215,230,240,270,288,300]
y2=[48,48,48,48,49,89,162,237,302,378,443,472,522,597,628,661,690,702]
x3=[30,50,70,90,105,114,128,137,147,159,170,180,190,200,210,230,243,259,284,297,311]
y3=[48,48,48,48,66,173,351,472,586,712,804,899,994,1094,1198,1360,1458,1578,1734,1797,1892]

l1=plt.plot(x1,y1,'r--',label='type1')
l2=plt.plot(x2,y2,'g--',label='type2')
l3=plt.plot(x3,y3,'b--',label='type3')

plt.plot(x1,y1,'ro-',x2,y2,'g+-',x3,y3,'b^-')
plt.title('X-Y-Z')
plt.xlabel('row')
plt.ylabel('column')
plt.legend()
plt.show()
```


### python 拟合
```python
#python3
#coding:utf-8
import matplotlib.font_manager
import matplotlib.pyplot as plt
import numpy as np

x = np.arange(1, 17, 1)
y = np.array([4.00, 6.40, 8.00, 8.80, 9.22, 9.50, 9.70, 9.86, 10.00, 10.20, 10.32, 10.42, 10.50, 10.55, 10.58, 10.60])
z1 = np.polyfit(x, y, 4) # 用4次多项式拟合
p1 = np.poly1d(z1)
print(p1) #print log 
yvals=p1(x) # 也可以使用yvals=np.polyval(z1,x)
plot1=plt.plot(x, y, '*',label='original values')
plot2=plt.plot(x, yvals, 'r',label='polyfit values')
plt.xlabel('x axis')
plt.ylabel('y axis')
plt.legend(loc=4) #
plt.title('polyfitting')
plt.show()

```

### 傅立叶变换
```python
#python3
#coding:utf-8

import matplotlib.font_manager
import numpy as np
from scipy import fftpack,signal

import matplotlib.pyplot as plt
b = 30
f_s = 80
N = 8000
t = np.linspace(0, 10, N, endpoint=False)
sq = signal.square(2 * np.pi * 5 * t)

F = fftpack.fft(sq)
f = fftpack.fftfreq(N, 1.0/f_s)

F_filtered = F * (abs(f) < 5)
print "F_filtered", F_filtered
ift = fftpack.ifft(F_filtered)
mask = np.where(f >= 0)

fig, axes = plt.subplots(4,1)
axes[0].plot(t, sq)
axes[0].set_ylim(-2, 2)
axes[1].plot(f[mask], abs(F[mask])/N, label="freq")
axes[2].plot(t,ift.real, label="all")
axes[3].plot(t,ift.real, label="zoom")
axes[3].set_xlim(1, 2)
plt.show()
```
绘图效果
![images](https://raw.githubusercontent.com/ordiychen/study_notes/master/res/image/node_image/blog_20200714163112.png)

# 参考
[Scipy Tutorial- 方波傅里叶分解与合成](http://liao.cpython.org/scipytutorial18/)