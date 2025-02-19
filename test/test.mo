import M "../src";
import Field "../src/field";
import IntExt "../src/intext";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";

let p = M.p();

func consumeIter(iter : Iter.Iter<Nat>, expect : [Nat]) {
  assert(iter.next() == ?expect[0]);
  assert(iter.next() == ?expect[1]);
};

func iterTest() {
  let a = [1, 2, 3, 4, 5];
  let b = a.vals();
  let c = b;
  let d = a.vals();
  consumeIter(b, [1, 2]);
  consumeIter(c, [3, 4]);
  consumeIter(d, [1, 2]);
};

func optionFunc(v:Nat) : ?Nat {
  if (v == 0) return null;
  ?v
};

func toReverseBinTest() {
  let tbl = [
    (0, []:[Bool]),
    (1, [true]),
    (2, [false, true]),
  ];
  for(i in tbl.keys()) {
    let (v, a) = tbl[i];
    let b = M.toReverseBin(v);
    assert(b == a);
  };
  switch (optionFunc(5)) {
    case(null) { assert(false); };
    case(?v) { assert(v == 5); };
  };
};

func toBigEndianTest() {
  let tbl = [
    ([0] : [Nat8], 0x0),
    ([0x12] : [Nat8], 0x12),
    ([0x12, 0x34] : [Nat8], 0x1234),
    ([0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0] : [Nat8], 0x123456789abcdef0),
    ([0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0, 0x12] : [Nat8], 0x123456789abcdef012),
  ];
  for (i in tbl.keys()) {
    let (b, v) = tbl[i];
    assert(M.toBigEndian(v) == b);
  };
};

func toBigEndianPadTest() {
  let tbl = [
    ([] : [Nat8], 0x0),
    ([0x12] : [Nat8], 0x12),
    ([0x12, 0x34] : [Nat8], 0x1234),
    ([0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0] : [Nat8], 0x123456789abcdef0),
    ([0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0, 0x12] : [Nat8], 0x123456789abcdef012),
  ];
  for (i in tbl.keys()) {
    let (b, v) = tbl[i];
    assert(M.toNatAsBigEndian(b.vals()) == v);
    assert(M.toBigEndianPad(b.size(), v) == b);
  };
  assert(M.toBigEndianPad(1, 0) == ([0x00] : [Nat8]));
  assert(M.toBigEndianPad(5, 0x1234) == ([0x00, 0x00, 0x00, 0x12, 0x34] : [Nat8]));
};

func arithTest() {
  let m1 = 5 * 2 ** 128;
  let m2 = 6 * 2 ** 128;
  var x1 = M.Fp.fromNat(m1);
  var x2 = M.Fp.fromNat(m2);
  assert(M.Fp.add(x1, x2) == M.Fp.fromNat(m1 + m2));
  assert(M.Fp.sub(x1, x2) == M.Fp.fromNat(m1 + p - m2 : Nat));
  assert(M.Fp.sub(x2, x1) == M.Fp.fromNat(m2 - m1 : Nat));
  assert(M.Fp.neg(#fp(0)) == #fp(0));
  assert(M.Fp.neg(x1) == M.Fp.fromNat(p - m1 : Nat));
  assert(M.Fp.mul(x1, x2) == M.Fp.fromNat(m1 * m2));

  var i = 0;
  x2 := #fp(1);
  while (i < 30) {
    assert(x2 == M.Fp.pow(x1, i));
    x2 := M.Fp.mul(x2, x1);
    i += 1;
  };
};

func invTest() {
  let inv123 = Field.inv_(123, 65537);
  assert(inv123 == 14919);
  let x2 = M.Fp.inv(#fp(123));
  var i = 1;
  while (i < 20) {
    let x1 = #fp(i);
    assert(M.Fp.mul(x1, M.Fp.inv(x1)) == #fp(1));
    assert(M.Fp.mul(M.Fp.div(x2, x1), x1) == x2);
    i += 1;
  };
};

func sqrRootTest() {
  var i = 0;
  while (i < 30) {
//    Debug.print("i=" # M.toHex(i));
    switch (M.fpSqrRoot(#fp(i))) {
      case (null) { };
      case (?sq) {
//        Debug.print("sq=" # M.toHex(sq));
        assert(M.Fp.sqr(sq) == #fp(i));
      };
    };
    i += 1;
  };
};

func gcdTest(f : (Int, Int) -> (Int, Int, Int)) {
  let (gcd1, gcd2, gcd3) = f(100, 37);
  assert(gcd1 == 1);
  assert(gcd2 == 10);
  assert(gcd3 == -27);
  let (a, b, c) = f(0, 37);
  assert(a == 37);
  assert(b == 0);
  assert(c == 1);
};

func ec1Test() {
  let Z = M.zero;
  assert(M.isZero(Z));
  assert(M.isZero(M.neg(Z)));
  assert(M.isZero(M.add(Z,Z)));

  let P = M.g;
  assert(not M.isZero(P));
  let Q = M.neg(P);
  assert(not M.isZero(Q));
  assert(M.isNegOf(P,Q));
  assert(M.isNegOf(Q,P));
  assert(M.isZero(M.add(P,Q)));
};

func ec2Teset() {
  let okP = (#fp(0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798), #fp(0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8));
  let okP2 = (#fp(0xc6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5), #fp(0x1ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a));
  let okP3 = (#fp(0xf9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9), #fp(0x388f7b0f632de8140fe337e62a37f3566500a99934c2231b6cb9fd7584b8e672));

  let P = M.g;
  assert(P == #affine(okP));
  let P2 = M.add(P,P);
  assert(P2 == #affine(okP2));
  let P3 = M.add(P2,P);
  assert(P3 == #affine(okP3));
  let P4 = M.add(P3,P);
  let P5 = M.add(P4,P);
  assert(M.isZero(M.add(P,M.neg(P))));
  assert(M.dbl(P) == P2);
  assert(M.mul(P,#fr(1)) == P);
  assert(M.mul(P,#fr(2)) == P2);
  assert(M.mul(P,#fr(3)) == P3);
  assert(M.mul(P,#fr(4)) == P4);
  assert(M.mul(P,#fr(5)) == P5);
  let Q = M.mul(P,M.Fr.fromNat(M.r() - 1));
  assert(Q == M.neg(P));
  assert(M.isZero(M.add(Q,P)));
  assert(M.isZero(M.mul(P,M.Fr.fromNat(M.r()))));
};

func ecdsaTest() {
  let secRand : [Nat8] = [ 0x83, 0xec, 0xb3, 0x98, 0x4a, 0x4f, 0x9f, 0xf0, 0x3e, 0x84, 0xd5, 0xf9, 0xc0, 0xd7, 0xf8, 0x88, 0xa8, 0x18, 0x33, 0x64, 0x30, 0x47, 0xac, 0xc5, 0x8e, 0xb6, 0x43, 0x1e, 0x01, 0xd9, 0xba, 0xc8 ];

  let signRand : [Nat8] = [ 0x8a, 0xfa, 0x4a, 0x16, 0x2b, 0x7b, 0xad, 0x6c, 0x92, 0xff, 0x14, 0xf3, 0xa8, 0xbf, 0x4d, 0xb0, 0xf3, 0xc3, 0x9e, 0x90, 0xc0, 0x6f, 0x93, 0x78, 0x61, 0xf8, 0x23, 0xd2, 0x99, 0x5c, 0x74, 0xf0 ];
  let hello : [Nat8] = [ 0x68, 0x65, 0x6c, 0x6c, 0x6f ];
  // sha256('hello')
  let hashed : [Nat8] = [ 0x2c, 0xf2, 0x4d, 0xba, 0x5f, 0xb0, 0xa3, 0x0e, 0x26, 0xe8, 0x3b, 0x2a, 0xc5, 0xb9, 0xe2, 0x9e, 0x1b, 0x16, 0x1e, 0x5c, 0x1f, 0xa7, 0x42, 0x5e, 0x73, 0x04, 0x33, 0x62, 0x93, 0x8b, 0x98, 0x24 ];
  assert(Blob.toArray(M.sha2(hello.vals())) == hashed);

  do {
    let sec = switch (M.getSecretKey(secRand.vals())) {
      case(null) { #fr(0) };
      case(?v) { v };
    };
    assert(sec == #fr(0x83ecb3984a4f9ff03e84d5f9c0d7f888a81833643047acc58eb6431e01d9bac8));
    let pub = M.getPublicKey(sec);
    assert(pub == (#fp(0x653bd02ba1367e5d4cd695b6f857d1cd90d4d8d42bc155d85377b7d2d0ed2e71), #fp(0x04e8f5da403ab78decec1f19e2396739ea544e2b14159beb5091b30b418b813a)));
    let sig = Option.get(M.signHashed(sec, hashed.vals(), signRand.vals()), (#fr(0), #fr(0)));
    assert(M.verifyHashed(pub, hashed.vals(), sig));
    assert(not M.verifyHashed((pub.0, M.Fp.add(pub.1,#fp(1))), hashed.vals(), sig));
    assert(not M.verifyHashed(pub, ([0x1, 0x2] : [Nat8]).vals(), sig));
    assert(M.sign(sec, hello.vals(), signRand.vals()) == ?sig);
    assert(M.verifyHashed(pub, hashed.vals(), sig));

    let sig2 = M.normalizeSignature(#fr(0xa598a8030da6d86c6bc7f2f5144ea549d28211ea58faa70ebf4c1e665c1fe9b5), #fr(0xde5d79a2ba44e311d04fdca263639283965780bce9169822be9cc81756e95a24));
    assert(M.verify(pub, hello.vals(), sig2));
  };

  // generated values by Python:ecdsa
  do {
    let sec = #fr(0xb1aa6282b14e5ffbf6d12f783612f804e6a20d1a9734ffbb6c9923c670ee8da2);
    let pub = M.getPublicKey(sec);
    assert(pub == (#fp(0x0a09ff142d94bc3f56c5c81b75ea3b06b082c5263fbb5bd88c619fc6393dda3d), #fp(0xa53e0e930892cdb7799eea8fd45b9fff377d838f4106454289ae8a080b111f8d)));
    let sig = M.normalizeSignature(#fr(0x50839a97404c24ec39455b996e4888477fd61bcf0ffb960c7ffa3bef10450191), #fr(0x9671b8315bb5c1611d422d49cbbe7e80c6b463215bfad1c16ca73172155bf31a));
    assert(M.verifyHashed(pub, hashed.vals(), sig));
  };
};

func serializeTest() {
  let expected = Blob.fromArray([0x04,0xa,0x9,0xff,0x14,0x2d,0x94,0xbc,0x3f,0x56,0xc5,0xc8,0x1b,0x75,0xea,0x3b,0x6,0xb0,0x82,0xc5,0x26,0x3f,0xbb,0x5b,0xd8,0x8c,0x61,0x9f,0xc6,0x39,0x3d,0xda,0x3d,0xa5,0x3e,0xe,0x93,0x8,0x92,0xcd,0xb7,0x79,0x9e,0xea,0x8f,0xd4,0x5b,0x9f,0xff,0x37,0x7d,0x83,0x8f,0x41,0x6,0x45,0x42,0x89,0xae,0x8a,0x8,0xb,0x11,0x1f,0x8d]);
  let pub = (#fp(0x0a09ff142d94bc3f56c5c81b75ea3b06b082c5263fbb5bd88c619fc6393dda3d), #fp(0xa53e0e930892cdb7799eea8fd45b9fff377d838f4106454289ae8a080b111f8d));
  do {
    let v = M.serializePublicKeyUncompressed(pub);
    assert(v == expected);
    let pub2 = M.deserializePublicKeyUncompressed(v);
    assert(pub2 == ?pub);
  };
  do {
    let v = M.serializePublicKeyCompressed(pub);
    assert(M.deserializePublicKeyCompressed(v) == ?pub);
    let pub2 = (pub.0, M.Fp.neg(pub.1));
    let v2 = M.serializePublicKeyCompressed(pub2);
    assert(M.deserializePublicKeyCompressed(v2) == ?pub2);
  };
};

func derTest() {
  let sig = (0xed81ff192e75a3fd2304004dcadb746fa5e24c5031ccfcf21320b0277457c98f, 0x7a986d955c6e0cb35d446a89d3f56100f4d7f67801c31967743a9c8e10615bed);
  let expected : [Nat8] = [0x30, 0x45, 0x02, 0x21, 0x00, 0xed, 0x81, 0xff, 0x19, 0x2e, 0x75, 0xa3, 0xfd, 0x23, 0x04, 0x00, 0x4d, 0xca, 0xdb, 0x74, 0x6f, 0xa5, 0xe2, 0x4c, 0x50, 0x31, 0xcc, 0xfc, 0xf2, 0x13, 0x20, 0xb0, 0x27, 0x74, 0x57, 0xc9, 0x8f, 0x02, 0x20, 0x7a, 0x98, 0x6d, 0x95, 0x5c, 0x6e, 0x0c, 0xb3, 0x5d, 0x44, 0x6a, 0x89, 0xd3, 0xf5, 0x61, 0x00, 0xf4, 0xd7, 0xf6, 0x78, 0x01, 0xc3, 0x19, 0x67, 0x74, 0x3a, 0x9c, 0x8e, 0x10, 0x61, 0x5b, 0xed];
  let der = M.serializeSignatureDer(sig);
//  M.dump(expected.vals());
//  M.dump(Blob.toArray(der).vals());
  assert(Blob.toArray(der) == expected);
  assert(M.deserializeSignatureDer(der) == ?sig);
};

toBigEndianPadTest();
toBigEndianTest();
toReverseBinTest();
iterTest();

// test lib.mo
arithTest();
invTest();
sqrRootTest();
gcdTest(IntExt.extGcd);
gcdTest(IntExt.extGcd_nr);
ec1Test();
ec2Teset();
ecdsaTest();
serializeTest();
derTest();
