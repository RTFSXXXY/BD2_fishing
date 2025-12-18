#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2

; Client 模式以游戏窗口的左上角为(0,0)，不包含标题栏和边框
CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

; 默认对当前激活的窗口生效
TargetWinTitle := "A" 

; 基准分辨率
BaseWidth := 1920
BaseHeight := 1080

; 全局变量存储缩放比例
Global ScaleX := 1
Global ScaleY := 1

F2:: {
    Global ScaleX, ScaleY
    SoundBeep(750, 200)

    ; === 第一步：获取当前窗口大小并计算缩放比例 ===
    try {
        WinGetClientPos &WinX, &WinY, &WinW, &WinH, TargetWinTitle
        ScaleX := WinW / BaseWidth
        ScaleY := WinH / BaseHeight
    } catch {
        MsgBox "未找到窗口"
        Return
    }

    Loop {
        ; 尝试抛竿
        if (!Cast()) {
            Send("{s down}")
            Sleep(500)
            Send("{s up}")
            Continue
        }

        FishingStartTime := A_TickCount
        LossTargetTime := 0 

        Loop {
            flag := False

            While (IsVerticalBarWhite(RX(968), RY(143), RY(148))) {
                Click
                Sleep 200
                Flag := True
            }
            if (flag) {
                Break 
            }

            ; 2. 检测超时
            if (A_TickCount - FishingStartTime > 60000) { 
                SoundBeep(300, 500)
                Break 
            }

            ; 3. 执行小游戏逻辑
            if (Draw()) {
                LossTargetTime := 0 
            } else {
                if (LossTargetTime == 0) {
                    LossTargetTime := A_TickCount 
                } else {
                    if (A_TickCount - LossTargetTime > 3000) {
                        SoundBeep(300, 200)
                        SoundBeep(300, 200)
                        Break 
                    }
                }
            }
        }
    }
}

F4::{
    SoundBeep(500, 200)
    Reload
}
F12::ExitApp

RX(x) {
    return Round(x * ScaleX)
}

RY(y) {
    return Round(y * ScaleY)
}

IsVerticalBarWhite(x, y1, y2) {
    MidY := (y1 + y2) // 2
    if (PixelGetColor(x, MidY) != "0xFFFFFF")
        return false
    if (PixelGetColor(x, y1) != "0xFFFFFF")
        return false
    if (PixelGetColor(x, y2) != "0xFFFFFF")
        return false
    return true
}

Sell() {
    ; 点商店（T）
    Click(RX(1379), RY(63))
    Sleep(1200)
    
    ; 点“一键出售”
    Click(RX(1600), RY(1000))
    Sleep(250)
    
    ; 点“全选”
    Click(RX(1600), RY(1000))
    Sleep(250)
    
    ; 点“√”
    Click(RX(1764), RY(1004))
    Sleep(250)
    
    ; 点“确定”
    Click(RX(1079), RY(641), "Down")
    Sleep(150)
    Click("Up")
    Sleep(1000)
    
    ; 点“返回”
    Click(RX(171), RY(50))
    Sleep(500)

    ; 屏幕中间点一下
    Click(RX(950), RY(500))
    Sleep(200)
}

Cast() {
    MouseMove(RX(1734), RY(894))
    Click "Down"
    StartTime := A_TickCount
    Loop {
        ; 进度条变绿检测
        if PixelGetColor(RX(1611), RY(925)) == 0x7EE522 {
            break 
        }
        if (A_TickCount - StartTime > 2000) {
            SoundBeep(200, 200)
            Click "Up" 
            Sell()
            return False
        }
        Sleep(10)
    }
    Click "Up"
    StartTime := A_TickCount
    Loop {
        ; 上钩检测
        if PixelGetColor(RX(1704), RY(787)) == 0xFFFFFF {
            break 
        }
        if (A_TickCount - StartTime > 10000) {
            SoundBeep(200, 200)
            return False
        }
        Sleep(10)
    }
    Click
    return True
}

Draw() {
    ; 搜索区域
    x1 := RX(767)
    y1 := RY(926)
    x2 := RX(1231)
    y2 := RY(963)

    ; 检查光标是否被冻住了
    if PixelSearch(&FrozenX, &FrozenY, x1, y1, x2, y2, 0xA90404, 40) {
        Loop 3 {
            Click
            Sleep 100
        }
    }
    ; 尝试搜寻黄色区域
    if PixelSearch(&YellowX, &YellowY, x1, y1, x2, y2, 0xFFE25A, 40) {
        StartTime := A_TickCount
        Loop {
            if PixelGetColor(YellowX, YellowY) == 0xFFFFFF {
                Click
                Sleep 150
                break 
            }
            if (A_TickCount - StartTime > 50) {
                break
            }
        }
        return True 
    }
    return False 
}
