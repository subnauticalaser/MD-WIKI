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

```txt
Window:SetAccent(<color3> accent)
```


##### **Keybind**
```lua
Window:SetKey(keycode)
```

```txt
Window:SetKey(<keycode> toggleKey)
```



##### **Toggle Window**
```lua
Window:Toggle(false)
```

```txt
Window:Toggle(<bool> toggled)
```



### **Tab**

#### **Creating Section**

```lua
local Section = Tab:AddSection("Section", {default = false})
```

```txt
Tab:AddSection(<table> {
    <string> name
    <table> options {
        <bool> default
    }
})
```


#### **Changing Tab**

##### **Show**

```txt
Tab:Show()
```

##### **Hide**

```txt
Tab:Hide()
```

##### **Extra**

```txt
Tab:AddConfigs()  ->  integrated configs system (to change path, modify 'Library.Settings.ConfigPath')
```

### **Section**

#### **Create Button**

```lua
local Button = Section:AddButton("Button", function()
	print("Button has been pressed")
end)
```

```txt
Section:AddButton(<table> {
    <string> name
    <void> callback
})
```


#### **Create Toggle**

```lua
local Toggle = Section:AddToggle("Toggle", {flag = "Toggle_Flag", default = false}, function(bool)
	print("Toggle set to:", bool)
end)
```

```txt
Section:AddToggle(<table> {
    <string> name
    <table> options {
        <bool> default
        <string> flag

    }
    <void> callback(<bool> enabled)
})
```


#### **Create Label**

```lua
local Label = Section:AddLabel("Label")
```

```txt
Section:AddLabel(<table> {
    <string> text
})
```


#### **Create DualLabel**

```lua
local DualLabel = Section:AddDualLabel({"Dual", "Label"})
```

```txt
Section:AddDualLabel(<table> {
    <table> text {<string> text1, <string> text2}
})
```



#### **Create ClipboardLabel**

```lua
local ClipboardLabel = Section:AddClipboardLabel("ClipboardLabel", function()
	return "ClipboardLabel"
end)
```

```txt
Section:AddClipboardLabel(<table> {
    <string> name
    <void> callback()  ->  must return string
})
```


#### **Create TextBox**

```lua
local Box = Section:AddBox("Box", {fireonempty = true}, function(text)
	print(text)
end)
```

```txt
Section:AddBox(<table> {
    <string> name
    <table> options {
        <bool> clearonfocus
        <bool> fireonempty
    }
    <void> callback(<string> text)
})
```



#### **Create Slider**

```lua
local Slider = Section:AddSlider("Slider", 1, 100, 50, {toggleable = true, default = false, flag = "Slider_Flag", fireontoggle = true, fireondrag = true, rounded = true}, function(val, bool)
	print("Slider value:", val, " - Slider toggled:", bool)
end)
```

```txt
Section:AddSlider(<table> {
    <string> name
    <int> minValue
    <int> maxValue
    <int> value
    <table> options {
        <bool> toggleable
        <string> flag
        <bool> fireontoggle
        <bool> fireondrag
        <bool> rounded
    }
    <void> callback(<int> value)
})
```



#### **Create DualLabel**

```lua

```

```txt

```


#### **Create DualLabel**

```lua

```

```txt

```
