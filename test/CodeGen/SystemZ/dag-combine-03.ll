; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=s390x-linux-gnu -mcpu=z13 < %s  | FileCheck %s

; Test that DAGCombiner gets helped by getKnownBitsForTargetNode() when
; BITCAST nodes are involved on a big-endian target.
;
; The EXTRACT_VECTOR_ELT is done first into an i32, and then AND:ed with
; 1. The AND is not actually necessary since the element contains a CC (i1)
; value. Test that the BITCAST nodes in the DAG when computing KnownBits is
; handled so that the AND is removed. If this succeeds, this results in a CHI
; instead of TMLL.

define void @fun(i64 %a0) {
; CHECK-LABEL: fun:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    lghi %r1, 0
; CHECK-NEXT:  .LBB0_1: # %lab0
; CHECK-NEXT:    # =>This Inner Loop Header: Depth=1
; CHECK-NEXT:    la %r0, 2(%r1)
; CHECK-NEXT:    la %r1, 1(%r1)
; CHECK-NEXT:    cgr %r1, %r2
; CHECK-NEXT:    lhi %r3, 0
; CHECK-NEXT:    lochie %r3, 1
; CHECK-NEXT:    cgr %r0, %r2
; CHECK-NEXT:    lhi %r0, 0
; CHECK-NEXT:    lochie %r0, 1
; CHECK-NEXT:    vlvgp %v0, %r3, %r3
; CHECK-NEXT:    vlvgp %v1, %r0, %r0
; CHECK-NEXT:    vx %v0, %v0, %v1
; CHECK-NEXT:    vlgvf %r0, %v0, 1
; CHECK-NEXT:    chi %r0, 0
; CHECK-NEXT:    locghie %r1, 0
; CHECK-NEXT:    j .LBB0_1
entry:
  br label %lab0

lab0:
  %phi = phi i64 [ %sel, %lab0 ], [ 0, %entry ]
  %add = add nuw nsw i64 %phi, 1
  %add2 = add nuw nsw i64 %phi, 2
  %cmp = icmp eq i64 %add, %a0
  %cmp2 = icmp eq i64 %add2, %a0
  %ins = insertelement <2 x i1> undef, i1 %cmp, i32 0
  %ins2 = insertelement <2 x i1> undef, i1 %cmp2, i32 0
  %xor = xor <2 x i1> %ins, %ins2
  %extr = extractelement <2 x i1> %xor, i32 0

  %sel = select i1 %extr, i64 %add, i64 0
  br label %lab0
}
