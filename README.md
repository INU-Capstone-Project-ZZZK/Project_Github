# 가속도 센서 기반 수면 자세 개선 실시간 피드백 시스템
---

[개발 저장소 바로가기](https://github.com/INU-Capstone-Project-ZZZK/Project_Github)


[개발 일지 바로가기](https://inu-capstone-project-zzzk.github.io/)  

## 개발 배경  

척추건강과 역류성 식도염 환자를 위한 수면자세 개선 디바이스를 만들고자 한다.  

우리 디바이스의 핵심 기술은 사용자의 수면단계, 수면자세를 기반으로 적절한 진동 자극을 가해 사용자의 수면자세를 바꾸는 것이다.  

가속도 센서를 기반으로 수면 단계와 수면 자세를 결정하고 사용자에게 잠을 방해하지 않는 선에서 정자세 그리고 좌측을 보며 누은 자세를 취할 수 있게 유도한다.  

## 아키텍처  

전체적인 아키텍처는 다음과 같다.  

![Untitled](/images/architecture.PNG)  

사용자가 이용하는 인터페이스는 Flutter로 개발된 앱이며, 각 디바이스에서 송신하는 시그널을 라즈베리파이 피코 W Flutter 간 블루투스 통신을 통해 전달받는다.   

통신방법으로 블루투스를 선택한 이유는, 소켓을 이용한 TCP/IP는 라우터를 비롯한 로컬 네트워크가 필요하기 때문이다. 반면 블루투스의 경우 별도 로컬 네트워크가 필요없다는 장점이 존재하고, 일반적으로 사람이 수면 시 스마트폰이 몸 근처에 위치하는 거리는 블루투스로도 충분히 통신이 가능하다.  

Flutter 앱에는 사전에 학습된 3가지의 추론 모델이 내장되어 있으며, 모바일 환경에서 구동되는 만큼 Tensorflow Lite를 이용한 경량화 모델을 이용할 것이다.  


## 완성된 디바이스와 결과

총 두 개의 디바이스를 제작하였으며 각각 가슴 그리고 손목에 착용된다.  

가슴에 착용되는 디바이스는 수면자세 측정에 사용되고 수면 자세 변경 진동을 준다.   

손목에 착용되는 디바이스는 수면 단계 측정에 사용된다.  

### 가슴 디바이스

![Untitled](/images/device1.png) ![Untitled](/images/device1-1.PNG)   
실제 완성된 가슴 디바이스의 내부 모습과 착용한 모습이다.  

### 손목 디바이스
![Untitled](/images/device2.png)   
실제 완성된 손목 디바이스의 내부 모습과 착용한 모습이다.  

### 최종 사이즈 및 결과표    
![Untitled](/images/device_result.PNG)    



## 딥러닝 모델 구조 

가속도 센서를 이용해 수면단계를 판별하는 과정에서, 정확도를 산출하는 과정에서 많은 어려움이 있었다.   
전처리와 특징 추출을 변화시키고 Random Forest, SVM, DT 등의 머신러닝과 Dense, LSTM, GRU, CNN 등의 딥러닝 모델들을 적용하며 정확도를 개선하는 실험을 진행하였으나, 성능을 끌어올리기가 여간 쉽지 않았다.  
특히 Flutter에 학습 모델을 실어야 하기 때문에 최근 시계열 분야에서 압도적인 성능을 보이고 있는 트랜스포머 모델을 도입하지 못해 아쉬움이 있었는데, Flutter에 tflite 모델을 올리는 과정에서 LSTN, GRU 등 RNN 모델들이 실리지 않는 상황이 발생하여 기존에 실험했던 RNN 모델들을 사용하지 못하였고 유일하게 사용이 가능했던 Mobilenet 모델 중 최신 버전인 V3 모델을 사용하였다.  

### Mobilenet v3-small 아키텍처  

![Untitled](/images/mobilenet_v3_small_architecture.png)  

아키텍처에서 알 수 있듯이 Mobilenet V3 모델은 CNN 기반의 모델로 시계열 데이터로 학습시키기 위해서 1차원으로 구조를 변형 후 진행하였다.  

## 학습 전처리 과정 및 결과  

**Nature에 기재된 논문에서 소개한 전처리 기법을 사용하여 수면단계 분류**를 진행하였다. 추가적으로, **해당 논문에선 5중 Random Forest 모델을 이용하였으나, Flutter에 해당 모델을 올릴 수 없기에 CNN 계열의 경량화된 모델로 대체하여 실험하였다.**

[Sleep classification from wrist-worn accelerometer data using random forests](https://www.nature.com/articles/s41598-020-79217-x)

### 1. ENMO (Euclidean Norm Minus One)

첫번째로 ENMO이다. intensity을 구할 때 -1을 해주었다. -1을 해주는 이유는 중력의 평균크기인 1을 제거하기 위함이다.  

중력을 제거하였으므로 당연히 intensity-1이 0보다 작은경우 0값으로 해준다.  

이것을 수식으로 나타내면 다음과 같다.  

![Untitled](/images/pre1.png)

### 2. Tilt Angles

두번째 인자로 기울기 각도를 넣어주었다. 이 값은 가속도 데이터에서 기기의 공간적 기울기를 유추할 수 있어 더욱 특징을 뽑아낼 수 있다.  

즉 각 축의 기울기 각도를 계산하면, 기기의 공간적 방향과 회전 상태를 측정할 수 있다.  

기울기 각도는 가속도 센서의 raw 데이터를 보정하고, 기기의 실제 기울기를 파악하는 데 사용된다.  

이때 기울기 각도는 라디안 단위가 아닌 도 단위를 사용한다.  

![Untitled](/images/pre2.png)

### 3. LIDS (Locomotor Inactivity During Sleep)

**ENMO_sub** :

![Untitled](/images/pre3.png)

먼저 ENMO값에 0.02를 빼주어 값을 보정을 해준다.  

이는 센서 자체의 노이즈나 미세한 환경 변화로 인해 작은 값의 진동이 발생할 수 있기 때문이다.  

또한 수면 중에는 미세한 움직임이 빈번히 발생할 수 있기 때문에 이러한 작은 움직임은 실제로는 수면 단계나 수면의 질에 큰 영향을 미치지 않는 경우가 많기 때문이다.   

즉 실제로 의미 있는 움직임만을 반영하도록 하는 것이 의도이다.  


**ENMO_sub_smooth**:

![Untitled](/images/pre4.png)

ENMO_sub_smooth는 10분(600초) 간격으로 움직임의 총량을 계산한다.  

짧은 시간 동안의 움직임을 누적하여 더 안정적인 활동을 모니터링한다.  

이렇게 함으로서 순간적인 움직임보다 더 지속적인 활동 패턴을 추출할 수 있다.  


**LIDS_unfiltered 계산**:

![Untitled](/images/pre5.png)

LIDS_unfiltered는 ENMO_sub_smooth 값의 역수를 취하여 활동량이 적을수록 값이 커지도록 한다.  

이는 움직임이 적은 상태, 즉 비활동 상태를 강조하기 위함이다. +1을 하는 이유는 0으로 나누는 상황을 없애려고 하기 때문이다.  


**LIDS 계산**:

![Untitled](/images/pre6.png)

LIDS_unfiltered 값을 30분(1800초) 동안 이동 평균을 계산한다.   

LIDS 수면 중 신체의 움직임이 적은 상태를 평가하여, 수면 상태를 감지하는 데 도움이 된다.   

데이터의 전처리는 다음과 같았고 이에따라 총 입력 tensor는 [1920,5]의 크기가 되었다. 

구조가 [ENMO, ang_x, ang_y, ang_z, LIDS]인 입력tensor이다.  


### 결과

데이터를 전처리 하고 Class를 3개로 압축하였을 때 mobileNetV3-small에서 accuracy 68%로 약 10%의 성능향상을 이루어냈다.  
  
rem수면을 깊은 수면 단계로 예측하였을 때는 76%의 정확도를 보여주었다.  

![Untitled](/images/mobilenet_v3_result.PNG)  

## 수면 단계 판별 알고리즘 도입 및 검증 결과

완성된 모델로 수면 실험을 진행하면서 경험적으로 수면자세가 바뀔 때 수면단계도 따라 바뀌는 경우가 많음을 알았다.  

해당 관측 결과를 통해 알고리즘 또한 도입해 같이 사용하여 더욱 수면단계 측정 정확도를 끌어올렸다.  

실제로 완성된 디바이스와 갤럭시 워치를 동시에 착용해 수면 단계를 비교하며 수면 자세가 바뀔 때 수면 단계가 바뀌는지 검증을 진행하였다.  

### 검증 결과 1

![Untitled](/images/sleep_class_1-1.png) ![Untitled](/images/sleep_class_1-2.png)  

### 검증 결과 2

![Untitled](/images/sleep_class_2-1.png) ![Untitled](/images/sleep_class_2-2.png)  

### 검증 결과 3

![Untitled](/images/sleep_class_3-1.png) ![Untitled](/images/sleep_class_3-2.png)  

클래스를 3개로 한정지어 측정한 결과라 완전히 동일하다고 할 수는 없으나, 수면 자세가 바뀔 때 수면 단계 또한 내려가는 것을 확인할 수 있었고 알고리즘을 도입하는 것에 근거를 더할 수 있었다.  

## 실제 측정 및 결과  

### 수면자세 측정(디바이스 착용 X)

![Untitled](/images/sleep1.png) 

### 수면자세 측정(디바이스 착용 O)

![Untitled](/images/sleep2.png) 

### 최종 결과

![Untitled](/images/final_result.png) 

## 후기  

적절한 자세로 수면을 취하기 위해 디바이스를 착용한다는 불편함은 존재하나 그럼에도 불구하고 수면 자세의 확실한 변화를 확인할 수 있었다.  

결과적으로 디바이스를 착용하며 확인된 수면 자세 비율을 고려했을 때 제품의 초기 목적인 수면 중 자세 개선은 효과를 보였다.  
