# 1PodShuffle
**사용자의 취향 장르를 기반으로 랜덤 음악이 재생되는 어플리케이션**

![iOS](https://img.shields.io/badge/iOS-16.0%2B-blue)

<img src="https://github.com/user-attachments/assets/6fd48210-6d6d-4b07-9a25-c9ca7e9378a6" width="300" height="300"/>

---

### 🙂 실행하는 방법

[실행 방법](https://maize-erica-237.notion.site/1PodShuffle-216a1c6f6ce08070a224ea3552015b0f) 을 반드시 참고해주세요!

---


### ⭐️ 주요 기능
- **Core Data 기반 음악 및 취향 데이터 관리** : 
사용자 음악 및 선호도 정보를 CoreData를 활용하여 CRUD를 작업했습니다.

- **NotificationCenter를 활용한 데이터 상태 감지** : 
NotificationCenter를 통해 데이터 변경 사항을 감지하고 UI 및 상태를 변경했습니다.

- **MPRemoteCommandCenter 및 NowPlayingInfo 연동** :
MPRemoteCommandCenter와 MPNowPlayingInfoCenter를 연동하여 백그라운드에서 재생 및 제어했습니다.

- **스토리보드 레퍼런스 활용으로 협업 최적화** :
별도의 Storyboard로 분리하고 Storyboard Reference를 통해 통합, 협업 중 충돌을 최소화하기 위해서 사용했습니다.

- **사이즈 클래스에 따른 대응** :
사이즈 클래스에 맞춰서 iPhone, iPad 등 기기에 맞게 대응했습니다.

- **싱글톤 패턴 사용** :
하나의 인스턴스로 상태를 일관되게 관리하고, 메모리 사용을 최소화했습니다.
---

### ⭐️ 아키텍쳐 및 라이브러리
- **MVC 아키텍처 기반 구조화** :
코드의 모듈화와 역할 분리를 위해 MVC 아키텍처를 적용했습니다.

- **AVFoundation 기반 음악 재생 기능 구현** :
AVFoundation 프레임워크를 활용하여 음악을 재생 및 제어했습니다.

- **MarqueeLabel 라이브러리 적용을 통한 가사/제목 스크롤 처리** : 
긴 텍스트를 자연스럽게 수평 스크롤 처리하기 위해 MarqueeLabel을 도입하여 사용자 UI 가독성을 개선하였습니다.

---
### 📱주요 화면
<table>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/31208bae-dfb2-465a-84c8-b23323a17541"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/7631e32d-6872-43f3-914b-8e086c981c09"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/926c254c-84d7-4bc1-a018-3a55b74d40fa"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/5033b96f-2299-4813-809d-e48c2b9dbbd7"></td>
    <td align="center"><img src="https://github.com/user-attachments/assets/5cec3118-d53d-4e99-abc6-535f86204b8e"></td>
  </tr>
</table>

---

### 📁 파일 구조
```
├── RandomMusic
│   ├── App // 앱 생명주기 관련
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Data // 모델 및 데이터 관리
│   │   ├── DataManager.swift
│   │   └── RandomMusic.xcdatamodeld
│   ├── Enum // 열거형 정의
│   │   ├── FeedbackType.swift
│   │   ├── Genre.swift
│   │   └── ThumbnailResponseType.swift
│   ├── Etc // 기타 리소스
│   │   ├── Assets.xcassets
│   │   └── Base.lproj
│   ├── Info.plist
│   ├── Manager // 주요 기능을 담당하는 싱글톤 매니저 클래스
│   │   ├── PlayerManager.swift
│   │   ├── PreferenceManager.swift
│   │   └── RemoteManager.swift
│   ├── Model // 데이터 모델 및 CoreData 확장 정의
│   │   ├── PreferenceData+Extension.swift
│   │   ├── Song+Extension.swift
│   │   ├── SongModel.swift
│   │   └── SongResponse.swift
│   ├── Service // 네트워크 및 음악 관련 서비스 모듈
│   │   ├── Network
│   │   └── Song
│   ├── Util // 공용 유틸리티 클래스
│   │   ├── Throttle.swift
│   │   ├── TimeFormatter.swift
│   │   └── Toast.swift
│   └── View // UI 관련
│       ├── Cell
│       └── ViewController
```

---
### 📚 커밋 컨벤션
| 타입(Type) | 설명(Description)            | 예시(Example)                                 |
| ---------- | ---------------------------- | --------------------------------------------- |
| feat       | 새로운 기능 추가              | feat: 사용자 음악 추천 기능 추가              |
| fix        | 버그 수정                    | fix: 로그인 시 인증 오류 수정                 |
| docs       | 문서 관련 변경                | docs: README에 커밋 컨벤션 가이드 추가        |
| style      | 코드 포맷팅, 세미콜론 등 스타일 변경 | style: 코드 포맷팅 및 불필요한 공백 제거      |
| refactor   | 코드 리팩토링                 | refactor: 음악 추천 로직 리팩토링             |
| test       | 테스트 코드 추가/수정          | test: 로그인 기능 테스트 코드 추가            |
| chore      | 빌드, 설정 등 기타 변경사항      | chore: 패키지 매니저 버전 업데이트            |
| ui         | UI 추가/수정                  | ui: 메인 화면 UI 레이아웃 변경                |

---
### 🙇 구성원

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/28ade993-8128-45ef-acac-9925d932bf09" width="150"><br>
      <strong>강대훈</strong><br>
      <a href="https://github.com/kanghun1121">GitHub</a>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/28ab4396-2bd5-4d4d-90ea-5208a69776c5" width="150"><br>
      <strong>김종성</strong><br>
      <a href="https://github.com/jseongee">GitHub</a>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/90c7b71c-183a-4994-ac3c-71d5e2dc0c8a" width="150"><br>
      <strong>이동욱</strong><br>
      <a href="https://github.com/drfranken99">GitHub</a>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/c50aa0b7-9cf4-4866-846f-2940f8e70156" width="150"><br>
      <strong>이유정</strong><br>
      <a href="https://github.com/YUJEONGLEEEEE">GitHub</a>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/ba2246b2-f22b-40c0-b2ed-3c00d52bb645" width="150"><br>
      <strong>이주용</strong><br>
      <a href="https://github.com/twoweeks-y">GitHub</a>
    </td>
  </tr>
</table>
