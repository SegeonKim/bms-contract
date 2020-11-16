## Setup
1. Clone git repository
```
git clone https://github.com/SegeonKim/bms-contract.git
```

2. Install packages
```
(기존 미설치 시) $ npm install -g truffle 
$ npm install
```

3. node_modules/@trufflesuite/web3-provider-engine/subproviders/rpc.js 수정
- local
- dev
- prod
```
...
  // overwrite id to conflict with other concurrent users
  const sanitizedPayload = sanitizePayload(payload)
  const newPayload = createPayload(sanitizedPayload)
 
  let jwt_token = "{발급받은 jwt}";
   
  xhr({
    uri: targetUrl,
    method: 'POST',
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      // add for contest
      "Authorization": "Bearer " + jwt_token
    },
...
```

## 배포 및 테스트
1. 배포
```
(테스트넷) $ truffle migrate --network besuTest
(메인넷) $ truffle migrate --network besu
```

2. 테스트
```
(테스트넷) $ truffle test ./test/TestScenario.js --network besuTest
(메인넷) $ truffle test ./test/TestScenario.js --network besu
```