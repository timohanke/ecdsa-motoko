/**
 * Module      : fp.mo
 * Description : finite field
 * Copyright   : 2022 Mitsunari Shigeo
 * License     : Apache 2.0 with LLVM Exception
 * Maintainer  : herumi <herumi@nifty.com>
 * Stability   : Stable
 */

import Int "mo:base/Int";
import Nat8 "mo:base/Nat8";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import SHA2 "mo:sha2";

module {
  // secp256k1
  // Ec/Fp : y^2 = x^3 + ax + b
  // (gx, gy) in Ec
  // #Ec = r
  let p_ : Nat = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f;
  let a_ : Nat = 0;
  let b_ : Nat = 7;
  let r_ : Nat = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
  public let gx_ : Nat = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798;
  public let gy_ : Nat = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8;

  /// return the order of the field where Ec is defined.
  public func p() : Nat = p_;
  /// return the order of the generator of Ec.
  public func r() : Nat = r_;

  public func test_sha2(b : [Nat8]) : [Nat8] {
    Blob.toArray(SHA2.fromIter(#sha256, b.vals()))
  };

  public func toHex(x : Nat) : Text {
    if (x == 0) return "0";
    var ret = "";
    var t = x;
    while (t > 0) {
      ret := (switch (t % 16) {
        case 0 { "0" };
        case 1 { "1" };
        case 2 { "2" };
        case 3 { "3" };
        case 4 { "4" };
        case 5 { "5" };
        case 6 { "6" };
        case 7 { "7" };
        case 8 { "8" };
        case 9 { "9" };
        case 10 { "a" };
        case 11 { "b" };
        case 12 { "c" };
        case 13 { "d" };
        case 14 { "e" };
        case 15 { "f" };
        case _ { "*" };
      }) # ret;
      t /= 16;
    };
    ret
  };
  // 13 = 0b1101 => [true,false,true,ture]
  public func toReverseBin(x : Nat) : [Bool] {
    var ret : Buffer.Buffer<Bool> = Buffer.Buffer<Bool>(256);
    var t = x;
    while (t > 0) {
      ret.add((t % 2) == 1);
      t /= 2;
    };
    ret.toArray()
  };

  // return (gcd, x, y) such that gcd = a * x + b * y
  public func extGcd(a : Int, b : Int) : (Int, Int, Int) {
    if (a == 0) return (b, 0, 1);
    let (q, r) = (b/a, b%a);
    let (gcd, x, y) = extGcd(r, a);
    return (gcd, y - q * x, x)
  };
  // return rev such that x * rev mod p = 1 if success else 0
  public func invMod(x : Nat, p : Nat) : Nat {
    let (gcd, rev, _) = extGcd(x, p);
    assert(gcd == 1);
    let v = if (rev < 0) rev+p else rev;
    assert(0 <= v and v < p);
    Int.abs(v)
  };
  func addMod(x : Nat, y : Nat, p : Nat) : Nat {
    let z = x+y;
    if (z < p) z else z-p;
  };
  func mulMod(x : Nat, y : Nat, p : Nat) : Nat = (x * y) % p;
  func subMod(x : Nat, y : Nat, p : Nat) : Nat = if (x >= y) x-y else x+p-y;
  func divMod(x : Nat, y : Nat, p : Nat) : Nat = (x * invMod(y, p)) % p;
  func negMod(x : Nat, p : Nat) : Nat = if (x == 0) 0 else p - x;

  // mod fp functions
  public func fpAdd(x : Nat, y : Nat) : Nat = addMod(x, y, p_);
  public func fpMul(x : Nat, y : Nat) : Nat = mulMod(x, y, p_);
  public func fpSub(x : Nat, y : Nat) : Nat = subMod(x, y, p_);
  public func fpDiv(x : Nat, y : Nat) : Nat = divMod(x, y, p_);
  public func fpNeg(x : Nat) : Nat = negMod(x, p_);
  public func fpInv(x : Nat) : Nat = invMod(x, p_);

  // mod fr functions
  public func frAdd(x : Nat, y : Nat) : Nat = addMod(x, y, r_);
  public func frMul(x : Nat, y : Nat) : Nat = mulMod(x, y, r_);
  public func frSub(x : Nat, y : Nat) : Nat = subMod(x, y, r_);
  public func frDiv(x : Nat, y : Nat) : Nat = divMod(x, y, r_);
  public func frNeg(x : Nat) : Nat = negMod(x, r_);
  public func frInv(x : Nat) : Nat = invMod(x, r_);

  func _isValid(x : Nat, y : Nat) : Bool {
    // return y^2 == (x^2 + a)x + b
    let lhs = fpMul(y, y);
    let rhs = fpAdd(fpMul(fpAdd(fpMul(x, x), a_), x), b_);
    lhs == rhs
  };

  public class Ec() {
    var x_ : Nat = 0;
    var y_ : Nat = 0;
    var isZero_ : Bool = true;
    public func affine() : (Nat, Nat) = (x_, y_);
    public func x() : Nat = x_;
    public func y() : Nat = y_;
    public func set(x : Nat, y : Nat) : Bool {
      if (not _isValid(x, y)) return false;
      x_ := x;
      y_ := y;
      isZero_ := false;
      return true
    };
    public func setNoCheck(x : Nat, y : Nat) {
      x_ := x;
      y_ := y;
      isZero_ := false;
    };
    public func isZero() : Bool = isZero_;
    public func isValid() : Bool = isZero_ or _isValid(x_, y_);
    public func neg() : Ec = if (isZero()) Ec() else newEcNoCheck(x_, fpNeg(y_));
    // QQQ : how can I return *this?
    public func copy() : Ec = if (isZero()) Ec() else newEcNoCheck(x_, y_);
    public func add(rhs : Ec) : Ec {
      if (isZero()) return rhs;
      if (rhs.isZero()) return copy();
      var nume = 0;
      var deno = 0;
      let x2 = rhs.x();
      let y2 = rhs.y();
      if (x_ == x2) {
        // P + (-P) = 0
        if (y_ == fpNeg(y2)) return Ec();
        // dbl
        let xx = fpMul(x_, x_);
        let xx3 = fpAdd(fpAdd(xx, xx), xx);
        nume := fpAdd(xx3, a_);
        deno := fpAdd(y_, y_);
      } else {
        nume := fpSub(y_, y2);
        deno := fpSub(x_, x2);
      };
      let L = fpDiv(nume, deno);
      let x3 = fpSub(fpMul(L, L), fpAdd(x_, x2));
      let y3 = fpSub(fpMul(L, fpSub(x_, x3)), y_);
      return newEcNoCheck(x3, y3)
    };
    public func dbl() : Ec {
      if (isZero()) return Ec();
      var nume = 0;
      var deno = 0;
      // P + (-P) = 0
      if (y_ == 0) return Ec();
      let xx = fpMul(x_, x_);
      let xx3 = fpAdd(fpAdd(xx, xx), xx);
      nume := fpAdd(xx3, a_);
      deno := fpAdd(y_, y_);
      let L = fpDiv(nume, deno);
      let x3 = fpSub(fpMul(L, L), fpAdd(x_, x_));
      let y3 = fpSub(fpMul(L, fpSub(x_, x3)), y_);
      return newEcNoCheck(x3, y3)
    };
    public func equal(rhs : Ec) : Bool {
      if (isZero()) return rhs.isZero();
      if (rhs.isZero()) return false;
      // both are not zero
      return x_ == rhs.x() and y_ == rhs.y()
    };
    public func mul(x : Nat) : Ec {
      if (x == 0) return Ec();
      let bs = toReverseBin(x);
      let self = copy();
      var ret = Ec();
      let n = bs.size();
      var i = 0;
      while (i < n) {
        let b = bs[n - 1 - i];
        ret := ret.dbl();
        if (b) {
          ret := ret.add(self);
        };
        i += 1;
      };
      return ret
    };
    public func put() {
      if (isZero()) {
        Debug.print("0");
      } else {
        Debug.print("x=" # toHex(x_));
        Debug.print("y=" # toHex(y_));
      };
    };
  };
  public func newEc(x : Nat, y : Nat) : ?Ec {
    let P = Ec();
    if (P.set(x, y)) ?P else null
  };
  public func newEcNoCheck(x : Nat, y : Nat) : Ec {
    let P = Ec();
    P.setNoCheck(x, y);
    return P
  };
  /// return the generator of Ec
  public func newEcGenerator() : Ec = newEcNoCheck(gx_, gy_);
  // [0x12, 0x34] : [Nat] => 0x1234
  public func toNatAsBigEndian(b : [Nat8]) : Nat {
    var v = 0;
    for (e in b.vals()) {
      v := v * 256 + Nat8.toNat(e);
    };
    return v
  };
  /// get secret key from [Nat8]
  /// rand : 32-byte
  /// return secret key in [1, r_-1]
  public func getSecretKey(rand : [Nat8]) : ?Nat {
    let sec = toNatAsBigEndian(rand) % r_;
    if (sec == 0) null else ?sec
  };
  /// get public key from sec
  /// public key (x, y) is a point of elliptic curve
  public func getPublicKey(sec : Nat) : ?(Nat, Nat) {
    let P = newEcGenerator();
    let Q = P.mul(sec);
    if (Q.isZero()) null else ?(Q.x(), Q.y())
  };
  /// sign hashed by sec and rand
  /// hashed : 32-byte SHA-256 value of a message
  /// rand : 32-byte random value
  public func signHashed(sec : Nat, hashed : [Nat8], rand : [Nat8]) : ?(Nat, Nat) {
    if (sec == 0 or sec >= r_) return null;
    let k = toNatAsBigEndian(rand) % r_;
    if (k == 0) return null;
    let P = newEcGenerator();
    let Q = P.mul(k);
    if (Q.isZero()) return null;
    let r = Q.x() % r_;
    if (r == 0) return null;
    let z = toNatAsBigEndian(hashed) % r_;
    // s = (r * sec + z) / k
    let s = frDiv(frAdd(frMul(r, sec), z), k);
    return ?(r, s)
  };
  // verify a tuple of pub, hashed, and sig
  public func verifyHashed(pub : (Nat, Nat), hashed : [Nat8], sig : (Nat, Nat)) : Bool {
    let (r, s) = sig;
    if (r == 0 or r >= r_) return false;
    if (s == 0 or s >= r_) return false;
    let z = toNatAsBigEndian(hashed) % r_;
    let w = frInv(s);
    let u1 = frMul(z, w);
    let u2 = frMul(r, w);
    let P = newEcGenerator();
    let (x, y) = pub;
    let Q = newEcNoCheck(x, y);
    if (not Q.isValid()) return false;
    let R = P.mul(u1).add(Q.mul(u2));
    if (R.isZero()) return false;
    return (R.x() % r_) == r
  };
};
