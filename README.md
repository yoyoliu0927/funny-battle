# 主持人切台：尖刺場地分支

基於 `funny-battle-main (1).zip`，保留原版四種玩法與排版。

## 開啟

在 Godot 匯入 `project.godot`，按 F5。原本的「開打、干擾決鬥、閃光格檔、大亂鬥」保留，新入口「尖刺場地」在其下方。

也可直接匯入 `funny-battle-fork-spikes.zip`；壓縮包包含完整資料夾項目，`project.godot` 位於最外層。

## 尖刺場地

- 沿用原版的血條、角色切換、速度切換、地形編輯與三格道具列。
- 道具維持原本的 **1 香蕉、2 彈簧、3 時停**，點地面放置，使用原本的冷卻與場上道具數量限制。
- 彈簧用放置位置決定方向：放在角色左側往右彈、右側往左彈、正下方往上彈。往敵人方向是跳高下落連擊，往反方向是後撤開火；預覽只顯示彈簧傾斜的初始方向。
- 主角血量為 **8**，會主動走近、攻擊、接三段連擊，遇到衝刺預警則退避。自行走位會停在橋內，道具與敵方擊退仍有危險。
- BOSS 交替使用原本的拳／踢／斬連段、遠距離普攻、蓄力攻擊、遠距離追擊與橋邊衝刺。完整出招後會留收招空檔。
- 主角也會在時停與滑倒造成的機會中，使用原本的遠攻、蓄力與追擊。
- 香蕉固定只滑 64 距離，雙方都會中招；中央放只會短滑停住，預判 BOSS 衝到橋邊放香蕉才會滑落。
- 主角普通攻擊不會擊退或打斷 BOSS，BOSS 至少保留 1 點生命，需要香蕉配合尖刺過關。
- 彈簧與時停保留原本效果；彈簧也無法單獨把 BOSS 弄下橋。
- 任一方掉進尖刺就敗北；R 重來，Esc 回原選單。
- 沒有額外的開場說明、旁白、道具庫存或自訂關卡名稱。

## 變更範圍

原版已有檔案僅修改 `scripts/match.gd`，加入一個選單按鈕。原本的 `project.godot`、`duel.gd`、`duelist.gd`、三道具程式、素材與場景都保持原檔。

新增 `scenes/spikes.tscn`、`scripts/spike_duel.gd`、`scripts/spike_stage.gd`；新場景繼承原版 `duel.tscn` 與 `duel.gd`，尖刺地形繼承原版 `stage_edit.gd`。

決鬥場地圖示使用 `assets/props/banana.png` 與 `assets/props/spring.png`，皆為 CC0，來源與授權見 `assets/props/CREDITS.md`。show 模式的香蕉與彈簧仍保留原本的線稿造型。

## 驗證與打包

```sh
Godot --headless --editor --import --quit
Godot --headless --script res://tests/fork_test.gd
python3 tools/package_project.py
```

已通過 100 項檢查，包含主角主動走位、8 點血量、雙方三段連擊、混合招式、原選單與四模式、三道具、普通攻擊無擊退、中央香蕉短滑、30/60/120 FPS 下的邊緣預判過關、左右橋邊與重試。預覽見 `docs/previews/`。
