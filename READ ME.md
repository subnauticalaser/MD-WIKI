# Vynixius UI-Library

## Getting Started


### Get Started | Step 1


**Define Library**

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/UI-Libraries/main/Vynixius/Source.lua"))()
```


### Step 2

### **Library**


#### **Create Window**
```lua
local Window = Library:AddWindow({
	title = {"Vynixius", "UI Library"},
	theme = {
		Accent = Color3.fromRGB(0, 255, 0)
	},
	key = Enum.KeyCode.RightControl,
	default = true
})
```

U can follow this format:


```txt
Library:AddWindow(<table> {
    <table> title {
        <string> title1
        <string> title2
    }
    <table> theme {
        <color3> Accent
        <color3> TopbarColor
        <color3> SidebarColor
        <color3> BackgroundColor
        <color3> SectionColor
        <color3> TextColor
    }  -> optional
    <bool> default
    <keycode> key
})
```

#### **Send Notification**

Notification Doc:

```txt
Library:Notify(<table> {
    <string> title
    <string> text
    <int> duration
    <color3> color
})
```


### **Window**

#### **Create Tab**

```lua
local Tab = Window:AddTab("Tab", {default = false})
```

U can follow this format:

```txt
Window:AddTab(<table> {
    <string> name
    <table> options {
        <bool> default
    } 
})
```


#### **Changing Window**


##### **Accent**
```lua
Window:SetAccent(color)
```

format:

```txt
Window:SetAccent(<color3> accent)
```
