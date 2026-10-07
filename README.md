# OmniAI v2.4.1 반입 패키지 — sample2

이 폴더에는 도커 이미지 조각만 들어 있습니다. 단독으로는 쓸 수 없습니다.

- 조각 수: 25 개
- 무결성 확인: `cd images && sha256sum -c ../SHA256SUMS.txt`

## 사용법

`sample`, `sample2`, `sample3`, `sample4` 네 폴더를 같은 상위 폴더에 두고,
`sample` 폴더의 `restore-images.sh`(또는 `.bat`)를 실행하십시오.

설치 순서와 주의 사항은 `sample/README.md` 에 있습니다.

## 조각만 먼저 합치고 싶을 때 (Windows)

`sample2` 폴더의 `merge-rag-pipeline.bat` 을 실행하면 sample2·sample3·sample4 의 조각을
하나의 `rag-pipeline.tar.gz` 로 합칩니다. 세 폴더가 같은 상위 폴더에 있어야 합니다.

```
cd sample2
merge-rag-pipeline.bat                 상위 폴더에 생성
merge-rag-pipeline.bat D:\tmp          지정한 폴더에 생성
```

합친 뒤 SHA256 을 `sample/SHA256SUMS.txt` 와 대조해 자동으로 검증합니다.
약 4GB 의 여유 공간이 필요하고, 합치기와 검증에 각각 몇 분 걸립니다.

검증이 끝나면 이렇게 올립니다.

```
docker load -i rag-pipeline.tar.gz
```
