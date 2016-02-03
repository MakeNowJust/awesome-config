-- == ライブラリの読み込み ==
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")


--  == エラーハンドリング ==
-- 起動時のエラーを報告
if awesome.startup_errors then
  naughty.notify({
    preset = naughty.config.presets.critical,
    title = "Oops, there were errors during startup!",
    text = awesome.startup_errors,
  })
end

-- 起動後のエラーを報告
do
  local in_error = false
  awesome.connect_signal("debug::error", function (err)
    -- エラーがループになるのを回避
    if in_error then return end
    in_error = true

    naughty.notify({
      preset = naughty.config.presets.critical,
      title = "Oops, an error happened!",
      text = err,
    })
    in_error = false
  end)
end


-- == 起動時に実行されるコマンド ==

awful.util.shell = "/bin/sh"
awful.util.spawn_with_shell("pgrep fcitx || fcitx")
awful.util.spawn_with_shell("pgrep nm-applet || nm-applet")
awful.util.spawn_with_shell("pgrep xcompmgr || xcompmgr")
awful.util.spawn_with_shell("pgrep dropbox || dropbox")


-- == 変数の定義とか ==
-- テーマーの読み込み
beautiful.init(awful.util.getdir("config") .. "/theme.lua")

-- 端末とエディタ
terminal = "env LANG=en_US.UTF_8 mlterm"
modkey = "Mod4"

-- レイアウトの種類
local layouts = {
  awful.layout.suit.tile,
  awful.layout.suit.spiral,
  awful.layout.suit.floating,
  --awful.layout.suit.tile.left,
  --awful.layout.suit.tile.bottom,
  --awful.layout.suit.tile.top,
  --awful.layout.suit.fair,
  --awful.layout.suit.fair.horizontal,
  --awful.layout.suit.spiral.dwindle,
  --awful.layout.suit.max,
  --awful.layout.suit.max.fullscreen,
  --awful.layout.suit.magnifier,
}


-- == 壁紙の設定 ==
if beautiful.wallpaper then
  for s = 1, screen.count() do
    gears.wallpaper.maximized(beautiful.wallpaper, s, true)
  end
end


-- == タグの設定 ==
tags = {}
for s = 1, screen.count() do
  tags[s] = awful.tag({1, 2, 3, 4, 5, 6, 7, 8, 9}, s, layouts[1])
end


-- == Wibox ==
-- 時計ウィジェットを作成
mytextclock = awful.widget.textclock()

-- その他のウィジェットの変数
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
  awful.button({ }, 1, awful.tag.viewonly),
  awful.button({ modkey }, 1, awful.client.movetotag),
  awful.button({ }, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, awful.client.toggletag)
)
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
  awful.button({ }, 1, function (c)
    if c == client.focus then
      c.minimized = true
    else
      c.minimized = false
      if not c:isvisible() then
        awful.tag.viewonly(c:tags()[1])
      end
      client.focus = c
      c:raise()
    end
  end),
  awful.button({ }, 3, function ()
    if instance then
      instance:hide()
      instance = nil
    else
      instance = awful.menu.clients({
        theme = { width = 250 }
      })
    end
  end)
)

for s = 1, screen.count() do
  -- プロンプトを作成
  mypromptbox[s] = awful.widget.prompt()
  -- レイアウトボックスを作成
  mylayoutbox[s] = awful.widget.layoutbox(s)
  mylayoutbox[s]:buttons(
    awful.util.table.join(
      awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
      awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end)
    )
  )
  -- タグリストを作成
  mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

  -- ウィンドウ一覧（タスクリスト）を作成
  mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

  -- Wiboxを作成
  mywibox[s] = awful.wibox({
    position = "top",
    screen = s,
  })

  -- 左側のウィジェット
  local left_layout = wibox.layout.fixed.horizontal()
  left_layout:add(mytaglist[s])
  left_layout:add(mypromptbox[s])

  -- 右側のウィジェット
  local right_layout = wibox.layout.fixed.horizontal()
  if s == 1 then right_layout:add(wibox.widget.systray()) end
  right_layout:add(mytextclock)
  right_layout:add(mylayoutbox[s])

  local layout = wibox.layout.align.horizontal()
  layout:set_left(left_layout)
  layout:set_middle(mytasklist[s])
  layout:set_right(right_layout)

  mywibox[s]:set_widget(layout)
end


-- == マウスの割り当て ==
root.buttons(awful.util.table.join(
  awful.button({ }, 4, awful.tag.viewnext),
  awful.button({ }, 5, awful.tag.viewprev)
))


-- == キーボードの割り当て ==
-- 全ての状況で使うキー
globalkeys = awful.util.table.join(
  -- Mod+←/→でタグの移動
  awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
  awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),

  -- Mod+j/kでウィンドウの移動
  awful.key({ modkey,           }, "j", function ()
    awful.client.focus.byidx( 1)
    if client.focus then client.focus:raise() end
  end),
  awful.key({ modkey,           }, "k", function ()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
  end),

  -- Mod+J/Kでウィンドウの配置の入れ替え
  awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
  awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),

  -- Mod+Enterで端末の起動
  awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
  -- Mod+Rでawesomeの再起動
  awful.key({ modkey, "Shift"   }, "r", awesome.restart),
  -- Mod+Control+rでPCの再起動
  awful.key({ modkey, "Control"   }, "r", function ()
    awful.util.spawn_with_shell("zenity --question --text='PCを再起動しますか？' && systemctl reboot")
  end),
  -- Mod+Qでawesomeの終了（ログアウト）
  awful.key({ modkey, "Shift"   }, "q", awesome.quit),
  -- Mod+Control+qでPCのシャットダウン
  awful.key({ modkey, "Control" }, "q", function ()
    awful.util.spawn_with_shell("zenity --question --text='PCを終了しますか？' && systemctl poweroff")
  end),

  -- 配置位置の調整
  awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.01)    end),
  awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.01)    end),
  awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
  awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
  awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
  awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
  awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts, 1) end),

  -- プロンプトの起動
  awful.key({ modkey            }, "r",     function () mypromptbox[mouse.screen]:run() end),

  -- 音量の調整
  awful.key({                   }, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer set Master 5%+") end),
  awful.key({                   }, "XF86AudioLowerVolume", function () awful.util.spawn("amixer set Master 5%-") end),
  awful.key({                   }, "XF86AudioMute"       , function () awful.util.spawn("amixer set Master toggle") end),

  -- PrintScreenでスクショを撮る
  awful.key({                   }, "Print", function ()
    awful.util.spawn("scrot '%Y%m%d%H%M%S.png' -e 'mv $f ~/Pictures/ScreenShot/'")
  end),
  -- Alt+PrintScreenで現在のウィンドウのスクショ
  awful.key({ "Mod1"            }, "Print", function ()
    awful.util.spawn("scrot -u '%Y%m%d%H%M%S.png' -e 'mv $f ~/Pictures/ScreenShot/'")
  end)
)

-- ウィンドウ上で使えるキー
clientkeys = awful.util.table.join(
  -- Mod+Fでフルスクリーン
  awful.key({ modkey, "Shift"   }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
  -- Mod+Cで終了
  awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
  -- Mod+Shift+Spaceでウィンドウを浮かせる
  awful.key({ modkey, "Shift" }, "space",  awful.client.floating.toggle                     ),
  -- Mod+nでタスクリストに戻す
  awful.key({ modkey,           }, "n",      function (c) c.minimized = true end),
  -- Mod+mで最大表示にする/戻す
  awful.key({ modkey,           }, "m", function (c)
    c.maximized_horizontal = not c.maximized_horizontal
    c.maximized_vertical   = not c.maximized_vertical
  end)
)

-- キーボードの各数字とタグを結び付ける
for i = 1, 9 do
  globalkeys = awful.util.table.join(globalkeys,
    -- Mod+数字でそのタグに切り替え
    awful.key({ modkey }, "#" .. i + 9, function ()
      local screen = mouse.screen
      local tag = awful.tag.gettags(screen)[i]
      if tag then awful.tag.viewonly(tag) end
    end),
    -- Mod+Ctrl+数字で現在のタグに別のタグのウィンドウを合わせて表示/非表示にする
    awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
      local screen = mouse.screen
      local tag = awful.tag.gettags(screen)[i]
      if tag then awful.tag.viewtoggle(tag) end
    end),
    -- Mod+Shift+数字で現在のタグのウィンドウを別のタブへ移動する
    awful.key({ modkey, "Shift" }, "#" .. i + 9, function ()
      if client.focus then
        local tag = awful.tag.gettags(client.focus.screen)[i]
        if tag then awful.client.movetotag(tag) end
      end
    end)
  )
end

-- ウィンドウ上のボタンの割り当て
clientbuttons = awful.util.table.join(
  -- クリックでフォーカスが移る
  awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
  -- Mod+左クリックでウィンドウの移動
  awful.button({ modkey }, 1, awful.mouse.client.move),
  -- Mod+右クリックでウィンドウのサイズの変更
  awful.button({ modkey }, 3, awful.mouse.client.resize)
)

-- キーを実際に割り当てる
root.keys(globalkeys)


-- == ルール ==
awful.rules.rules = {
  -- 全てのウィンドウに当てはまるルール
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = clientkeys,
      buttons = clientbuttons,
    }
  },
}

-- 浮かせておきたいアプリケーション
for i, class in ipairs({"MPlayer", "gimp"}) do
  table.insert(awful.rules.rules, {
    rule = {
      class = class,
    },
    properties = {
      floting = true,
    },
  })
end


-- == シグナル ==
-- 新しいウィンドウができたときに送信されるシグナル
client.connect_signal("manage", function (c, startup)
  -- クリックで
  c:connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
       and awful.client.focus.filter(c) then
       client.focus = c
    end
  end)

  if not startup then
    -- 予め大きさや位置が指定されてないときは、いい感じの位置に調整する
    if not c.size_hints.user_position and not c.size_hints.program_position then
      awful.placement.no_overlap(c)
      awful.placement.no_offscreen(c)
    end
  end
end)

-- フォーカスされたときと外れたときに色を変える
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)


