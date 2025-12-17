#Requires AutoHotkey v2.0
#SingleInstance Force
#MaxThreadsPerHotkey 2
CoordMode "Pixel", "Screen"
CoordMode "Mouse", "Screen"

F2:: {
    SoundBeep(750, 200)
    Loop {
        ; 尝试抛竿，如果抛竿失败（没找到浮漂等）直接下一轮
        if (!Cast()) {
            ; 可能是没在船边，往下走两步
            Send("{s down}")
            Sleep(500)
            Send("{s up}")
            Continue
        }

        ; === 新增变量 ===
        FishingStartTime := A_TickCount ; 记录开始钓鱼的时间
        LossTargetTime := 0 ; 记录找不到黄色区域的开始时间

        Loop {
            flag := False

            ; 1. 检测是否成功（结算画面）
            While (IsVerticalBarWhite(968, 143, 148)) {
                Click
                Sleep 200
                Flag := True
            }
            if (flag) {
                Break ; 成功钓起，退出当前钓鱼循环，重新Cast
            }

            ; 2. 检测超时（防止鱼太难钓导致死循环）
            if (A_TickCount - FishingStartTime > 60000) { ; 60秒超时
                SoundBeep(300, 500) ; 低音长提示
                Break ; 强制结束本次钓鱼
            }

            ; 3. 执行小游戏逻辑，并接收返回值
            ; Draw() 返回 true(找到黄区) 或 false(没找到)
            if (Draw()) {
                ; 如果找到了黄色区域，说明还在游戏里，重置丢失计时
                LossTargetTime := 0 
            } else {
                ; 如果没找到黄色区域
                if (LossTargetTime == 0) {
                    LossTargetTime := A_TickCount ; 开始记录丢失时间
                } else {
                    ; 如果连续 3秒 都找不到黄色区域，说明失败（UI消失了）
                    if (A_TickCount - LossTargetTime > 3000) {
                        SoundBeep(300, 200) ; 失败提示音
                        SoundBeep(300, 200)
                        Break ; 强制结束
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
    Click(1379, 63)
    Sleep(1200)
    ; 点“一键出售”
    Click(1600, 1000)
    Sleep(250)
    ; 点“全选”
    Click(1600, 1000)
    Sleep(250)
    ; 点“√”
    Click(1764, 1004)
    Sleep(250)
    ; 点“确定”
    Click(1079, 641, "Down")
    Sleep(150)
    Click("Up")
    Sleep(1000)
    ; 点“返回”
    Click(171, 50)
    Sleep(500)

    ; 在屏幕中间点一下，关掉一些因为误触打开的窗口
    Click(950, 500)
    Sleep(200)
}

Cast() {
    MouseMove(1734, 894)
    Click "Down"
    StartTime := A_TickCount
    Loop {
        ; 当进度条变绿，松开左键
        if PixelGetColor(1611, 925) == 0x7EE522 {
            break 
        }
        if (A_TickCount - StartTime > 2000) {
            SoundBeep(200, 200)
            Click "Up" ; 超时松开鼠标
            ; 有可能是背包满了
            Sell()
            return False
        }
        Sleep(10)
    }
    Click "Up"
    StartTime := A_TickCount
    Loop {
        if PixelGetColor(1704, 787) == 0xFFFFFF {
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

; 返回 True 代表找到了黄色区域（说明正在进行游戏）
; 返回 False 代表没找到
Draw() {
    ; 检查光标是否被冻住了
    if PixelSearch(&FrozenX, &FrozenY, 767, 926, 1231, 963, 0xA90404, 40) {
        Loop 3 {
            Click
            Sleep 100
        }
    }
    ; 尝试搜寻黄色区域
    if PixelSearch(&YellowX, &YellowY, 767, 926, 1231, 963, 0xFFE25A, 40) {
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
        return True ; 找到了黄色区域
    }
    return False ; 没找到黄色区域

}
