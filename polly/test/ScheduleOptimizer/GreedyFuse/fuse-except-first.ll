; RUN: opt %loadNPMPolly -polly-reschedule=0 -polly-loopfusion-greedy=1 -polly-postopts=0 '-passes=print<polly-opt-isl>' -disable-output < %s | FileCheck %s --check-prefixes=CHECK,RAW
; RUN: opt %loadNPMPolly -polly-reschedule=1 -polly-loopfusion-greedy=1 -polly-postopts=0 '-passes=print<polly-opt-isl>' -disable-output < %s | FileCheck %s --check-prefixes=CHECK,OPT

define void @func(i32 %n, ptr noalias nonnull %A, ptr noalias nonnull %B, i32 %k) {
entry:
  br label %for1


for1:
  %j1 = phi i32 [0, %entry], [%j1.inc, %inc1]
  %j1.cmp = icmp slt i32 %j1, %n
  br i1 %j1.cmp, label %body1, label %exit1

    body1:
      %idx1 = add i32 %j1, %k
      %arrayidx1 = getelementptr inbounds double, ptr %B, i32 %idx1
      store double 21.0, ptr %arrayidx1
      br label %inc1

inc1:
  %j1.inc = add nuw nsw i32 %j1, 1
  br label %for1, !llvm.loop !1

exit1:
  br label %for2


for2:
  %j2 = phi i32 [0, %exit1], [%j2.inc, %inc2]
  %j2.cmp = icmp slt i32 %j2, %n
  br i1 %j2.cmp, label %body2, label %exit2

    body2:
      %arrayidx2 = getelementptr inbounds double, ptr %B, i32 %j2
      store double 42.0, ptr %arrayidx2
      br label %inc2

inc2:
  %j2.inc = add nuw nsw i32 %j2, 1
  br label %for2

exit2:
  br label %for3


for3:
  %j3 = phi i32 [0, %exit2], [%j3.inc, %inc3]
  %j3.cmp = icmp slt i32 %j3, %n
  br i1 %j3.cmp, label %body3, label %exit3

    body3:
      %arrayidx3 = getelementptr inbounds double, ptr %A, i32 %j3
      store double 84.0, ptr %arrayidx3
      br label %inc3

inc3:
  %j3.inc = add nuw nsw i32 %j3, 1
  br label %for3

exit3:
  br label %return


return:
  ret void
}


!1 = distinct !{!1, !2}
!2 = !{!"llvm.loop.id", !"Hello World!"}


; CHECK:      Calculated schedule:
; CHECK-NEXT: domain: "[n, k] -> { Stmt_body2[i0] : 0 <= i0 < n; Stmt_body1[i0] : 0 <= i0 < n; Stmt_body3[i0] : 0 <= i0 < n }"
; CHECK-NEXT: child:
; CHECK-NEXT:   sequence:
; CHECK-NEXT:   - filter: "[n, k] -> { Stmt_body1[i0] }"
; CHECK-NEXT:     child:
; RAW-NEXT:         mark: "Loop with Metadata"
; RAW-NEXT:         child:
; CHECK-NEXT:         schedule: "[n, k] -> [{ Stmt_body1[i0] -> [(i0)] }]"
; OPT-NEXT:           permutable: 1
; OPT-NEXT:           coincident: [ 1 ]
; CHECK-NEXT:   - filter: "[n, k] -> { Stmt_body2[i0]; Stmt_body3[i0] }"
; CHECK-NEXT:     child:
; CHECK-NEXT:       schedule: "[n, k] -> [{ Stmt_body2[i0] -> [(i0)]; Stmt_body3[i0] -> [(i0)] }]"
; CHECK-NEXT:       child:
; CHECK-NEXT:         sequence:
; CHECK-NEXT:         - filter: "[n, k] -> { Stmt_body2[i0] }"
; CHECK-NEXT:         - filter: "[n, k] -> { Stmt_body3[i0] }"
