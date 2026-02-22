-- ESP 404 Library
-- Provides a framework for managing and rendering 3D ESP drawings with tracers

-- This is more of a drawing library than an ESP library since ESPs really depends
-- on what the scripter wants for their specific situation.

-- If you need guidance, consider looking at other scripts on my GitHub that I've
-- made that use this library.

local genv = getgenv()

if not genv.Drawing or not genv.cleardrawcache then
    warn("Drawing is not supported with this executor!")
    return nil
end

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

ESP = {}

-- Drawing types
DRAW_TYPES = {
    BOX_3D = "box_3d";
    RECT_2D = "rect_2d";
    RECT_3D = "rect_3d";
    CIRCLE_2D = "circle_2d";
    CIRCLE_3D = "circle_3d";
    LINE_2D = "line_2d";
    LINE_3D = "line_3d";
    TEXT = "text";
}

-- Tracer configuration
TRACER_ORIGINS = {
    MOUSE = "mouse";
    BOTTOM = "bottom";
    TOP = "top";
    CENTER = "center";
}
ESP.TRACER_ORIGINS = TRACER_ORIGINS

TRACER_TARGETS = {
    CENTER = "center";
    TOP = "top";
    BOTTOM = "bottom";
}
ESP.TRACER_TARGETS = TRACER_TARGETS

-- Helpers
function AddDrawing(Type, Properties)
    local Drawing = Drawing.new(Type)
    for Index, Property in pairs(Properties) do
        Drawing[Index] = Property
    end
    return Drawing
end

function GetMyDistanceSquared(position: Vector3): number?
    assert(position, "[ERROR] GetMyDistanceSquared must be passed a Vector3!")
    local character = LocalPlayer.Character
    if not character then return nil end
    local humanoidrootpart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    local primarypart = character.PrimaryPart
    if not humanoidrootpart and not head and not primarypart then return nil end
    
	local p1 = humanoidrootpart and humanoidrootpart.Position or head and head.Position or primarypart and primarypart.Position
	local p2 = position

	local a = (p1.X - p2.X) * (p1.X - p2.X)
	local b = (p1.Y - p2.Y) * (p1.Y - p2.Y)
	local c = (p1.Z - p2.Z) * (p1.Z - p2.Z)
    
    return a+b+c
end
ESP.GetMyDistanceSquared = GetMyDistanceSquared

function GetMyDistance(position: Vector3): number?
    assert(position, "[ERROR] GetMyDistance must be passed a Vector3!")
    local distSquared = GetMyDistanceSquared(position)
    if not distSquared then return nil end
	return math.sqrt(distSquared)
end
ESP.GetMyDistance = GetMyDistance

function RoundUp(n: number): number
    assert(n and type(n) == "number", "[ERROR] RoundUp must be passed a number!")
    return math.floor(n + 0.5)
end
ESP.RoundUp = RoundUp

function GetBox3DCorners(p1: Vector3, p2: Vector3)
    return {
        Vector3.new(p1.X, p1.Y, p1.Z);
        Vector3.new(p1.X, p1.Y, p2.Z);
        Vector3.new(p1.X, p2.Y, p1.Z);
        Vector3.new(p1.X, p2.Y, p2.Z);

        Vector3.new(p2.X, p1.Y, p1.Z);
        Vector3.new(p2.X, p1.Y, p2.Z);
        Vector3.new(p2.X, p2.Y, p1.Z);
        Vector3.new(p2.X, p2.Y, p2.Z);
    }
end

function GetRect2DCorners(p1: Vector2, p2: Vector2)
    return {
        p1;
        Vector2.new(p1.X, p2.Y);
        p2;
        Vector2.new(p2.X, p1.Y);
    }
end

function CalculateRect2D(object: BasePart|Model)
    if not object then return end
    local CF, Size
    if object:IsA("Model") then
        CF, Size = object:GetBoundingBox()
    elseif object:IsA("BasePart") then
        CF = object.CFrame
        Size = object.Size
    end
	local Camera = workspace.CurrentCamera
	
	local CornerTable = {
		TopLeft = Camera:WorldToViewportPoint(Vector3.new(CF.X - Size.X / 2, CF.Y + Size.Y / 2, CF.Z)),
		TopRight = Camera:WorldToViewportPoint(Vector3.new(CF.X + Size.X / 2, CF.Y + Size.Y / 2, CF.Z)),
		BottomLeft = Camera:WorldToViewportPoint(Vector3.new(CF.X - Size.X / 2, CF.Y - Size.Y / 2, CF.Z)),
		BottomRight = Camera:WorldToViewportPoint(Vector3.new(CF.X + Size.X / 2, CF.Y - Size.Y / 2, CF.Z))
	}
	
	local ViewportPoint, OnScreen = Camera:WorldToViewportPoint(CF.Position)
	local ScreenSize = Vector2.new((CornerTable.TopLeft - CornerTable.TopRight).Magnitude, (CornerTable.TopLeft - CornerTable.BottomLeft).Magnitude)
    local ScreenPosition = Vector2.new(ViewportPoint.X - ScreenSize.X / 2, ViewportPoint.Y - ScreenSize.Y / 2)
	return {
        CF = CF;
        Size = Size;
        ViewportPoint = ViewportPoint;
		ScreenPosition = ScreenPosition;
		ScreenSize = ScreenSize;
		OnScreen = OnScreen;
	}
end
ESP.CalculateRect2D = CalculateRect2D

function CalculateBox3D(object: BasePart|Model)
    if not object then return end
    local rect2DCalculations = CalculateRect2D(object)
    local CF = rect2DCalculations.CF
    local Size = rect2DCalculations.Size

    local Pos1 = CF * CFrame.new(-Size.X/2, -Size.Y/2, -Size.Z/2)
    local Pos2 = CF * CFrame.new(Size.X/2, Size.Y/2, Size.Z/2)

    rect2DCalculations.Pos1 = Pos1
    rect2DCalculations.Pos2 = Pos2
    return rect2DCalculations
end
ESP.CalculateBox3D = CalculateBox3D

BOX_3D_EDGES = {
    {1,2}; {1,3}; {1,5};
    {8,7}; {8,6}; {8,4};
    {2,4}; {2,6};
    {3,4}; {3,7};
    {5,6}; {5,7};
}

BOX_3D_FACES = {
    -- Each face is 4 indices into the corners array
    {1,2,4,3}, -- Left
    {5,6,8,7}, -- Right
    {1,5,6,2}, -- Bottom
    {3,4,8,7}, -- Top
    {1,3,7,5}, -- Front
    {2,6,8,4}, -- Back
}

QUAD_2D_EDGES = {
    {1,2}; {2,3}; {3,4}; {4,1};
}

FONTS = {
    UI = 0;
    System = 1;
    Plex = 2;
    Monospace = 3;
}
ESP.FONTS = FONTS

PI = math.pi

function IsFaceVisible(pA, pB, pC)
    local AB = pB - pA
    local AC = pC - pA
    local crossZ = AB.X * AC.Y - AB.Y * AC.X
    return crossZ < 0 -- negative = facing camera (Roblox screen coords are flipped)
end

function GetScreenBounds(points)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, p in ipairs(points) do
        if p.X < minX then minX = p.X end
        if p.Y < minY then minY = p.Y end
        if p.X > maxX then maxX = p.X end
        if p.Y > maxY then maxY = p.Y end
    end

    return minX, minY, maxX, maxY
end

function GetTracerAnchors(points)
    local minX, minY, maxX, maxY = GetScreenBounds(points)

    local centerX = (minX + maxX) * 0.5
    local centerY = (minY + maxY) * 0.5

    return {
        Top = Vector2.new(centerX, minY),
        Center = Vector2.new(centerX, centerY),
        Bottom = Vector2.new(centerX, maxY),
    }
end

-- Drawing object constructor
function CreateDrawing(drawType, properties)
    properties = properties or {}
    
    local drawing = {
        type = drawType;
        visible = properties.visible ~= false and true or false;
        color = properties.color or Color3.new(1,1,1);
        tracer = properties.tracer or nil;
        data = properties.data or {};
    }
    
    -- Tracer configuration
    if properties.tracer then
        drawing.tracer = {
            origin = properties.tracer.origin or TRACER_ORIGINS.MOUSE;
            target = properties.tracer.target or TRACER_TARGETS.CENTER;
            color = properties.tracer.color or drawing.color;
        }
    end

    local Camera = workspace.CurrentCamera

    local ScreenPoints = {}
    if drawing.type == DRAW_TYPES.BOX_3D then
        local Pos1, Pos2 = drawing.data.Pos1, drawing.data.Pos2
        assert(Pos1 and typeof(Pos1) == "Vector3", "[ERROR] drawing.data.Pos1 must be a Vector3!")
        assert(Pos2 and typeof(Pos2) == "Vector3", "[ERROR] drawing.data.Pos2 must be a Vector3!")
        local BoxCorners = GetBox3DCorners(Pos1, Pos2)
        -- Project all corners
        local projected = {}
        for i, corner in ipairs(BoxCorners) do
            local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
            -- if not onScreen then
            --     -- If ANY corner is off-screen, you can choose to skip drawing
            --     -- or clamp it. For now, we skip.
            --     return
            -- end
            projected[i] = Vector2.new(screenPos.X, screenPos.Y)
        end
        ScreenPoints = projected

        if drawing.visible then
            -- Draw visible faces
            for _, face in ipairs(BOX_3D_FACES) do
                local A = projected[face[1]]
                local B = projected[face[2]]
                local C = projected[face[3]]
                local D = projected[face[4]]
                -- Cull backfaces
                if IsFaceVisible(A, B, C) then
                    local QuadCorners = {A, B, C, D}
                    -- Filled Quad
                    local Main = AddDrawing("Quad", {
                        --BaseDrawingObject
                        Visible = true;
                        ZIndex = (drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 1) + 1;
                        Transparency = drawing.data.FillTransparency ~= nil and type(drawing.data.FillTransparency) == "number" and drawing.data.FillTransparency >= 0 and drawing.data.FillTransparency <= 1 and drawing.data.FillTransparency or 1;
                        Color = drawing.data.FillColor or drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                        --Quad
                        PointA = A;
                        PointB = B;
                        PointC = C;
                        PointD = D;
                        Filled = drawing.data.Filled or true;
                        Thickness = 1;
                    })
                    -- Outline Quad
                    local Outline = AddDrawing("Quad", {
                        --BaseDrawingObject
                        Visible = true;
                        ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 1;
                        Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                        Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                        --Quad
                        PointA = A;
                        PointB = B;
                        PointC = C;
                        PointD = D;
                        Filled = false;
                        Thickness = drawing.data.Thickness or 2;
                    })
                end
            end
        end
    elseif drawing.type == DRAW_TYPES.RECT_2D then
        local Pos, Size = drawing.data.Pos, drawing.data.Size
        assert(Pos and typeof(Pos) == "Vector2", "[ERROR] drawing.data.Pos must be a Vector2!")
        assert(Size and typeof(Size) == "Vector2", "[ERROR] drawing.data.Size must be a Vector2!")

        if drawing.visible then
            -- Filled Square
            local Main = AddDrawing("Square", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex + 1 or 1;
                Transparency = drawing.data.FillTransparency ~= nil and type(drawing.data.FillTransparency) == "number" and drawing.data.FillTransparency >= 0 and drawing.data.FillTransparency <= 1 and drawing.data.FillTransparency or 1;
                Color = drawing.data.FillColor or drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Square
                Size = Size;
                Position = Pos;
                Thickness = 1;
                Filled = drawing.data.Filled ~= nil and type(drawing.data.Filled) == "boolean" and drawing.data.Filled or false;
            })
            -- Outline Square
            local Outline = AddDrawing("Square", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Square
                Size = Size;
                Position = Pos;
                Thickness = drawing.data.Thickness ~= nil and type(drawing.data.Thickness) == "number" and drawing.data.Thickness >= 0 or 3;
                Filled = false;
            })
        end

        ScreenPoints = {
            Pos + Vector2.new(-Size.X/2, -Size.X/2);
            Pos + Vector2.new(-Size.X/2, Size.X/2);
            Pos + Vector2.new(Size.X/2, Size.X/2);
            Pos + Vector2.new(Size.X/2, -Size.X/2);
        }
    elseif drawing.type == DRAW_TYPES.RECT_3D then
        local QuadCorners = drawing.data.QuadCorners
        assert(QuadCorners and type(QuadCorners) == "table", "[ERROR] drawing.data.QuadCorners must be a table!")
        assert(#QuadCorners == 4, "[ERROR] #drawing.data.QuadCorners must be equal to 4!")
        for i, v in ipairs(QuadCorners) do
            assert(v and typeof(v) == "Vector2", "[ERROR] drawing.data.QuadCorners["..tostring(i).."] must be a Vector2!")
        end

        if drawing.visible then
            -- Filled Quad
            local Main = AddDrawing("Quad", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex + 1 or 1;
                Transparency = drawing.data.FillTransparency ~= nil and type(drawing.data.FillTransparency) == "number" and drawing.data.FillTransparency >= 0 and drawing.data.FillTransparency <= 1 and drawing.data.FillTransparency or 1;
                Color = drawing.data.FillColor or drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Quad
                PointA = QuadCorners[1];
                PointB = QuadCorners[2];
                PointC = QuadCorners[3];
                PointD = QuadCorners[4];
                Thickness = 1;
                Filled = drawing.data.Filled ~= nil and type(drawing.data.Filled) == "boolean" and drawing.data.Filled or false;
            })
            -- Outline Quad
            local Outline = AddDrawing("Quad", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Quad
                PointA = QuadCorners[1];
                PointB = QuadCorners[2];
                PointC = QuadCorners[3];
                PointD = QuadCorners[4];
                Thickness = drawing.data.Thickness ~= nil and type(drawing.data.Thickness) == "number" and drawing.data.Thickness >= 0 or 3;
                Filled = false;
            })
        end

        ScreenPoints = QuadCorners
    elseif drawing.type == DRAW_TYPES.CIRCLE_2D then
        local Pos = drawing.data.CenterPos
        assert(Pos and typeof(Pos) == "Vector2", "[ERROR] drawing.data.CenterPos must be a Vector2!")
        local Radius = drawing.data.Radius ~= nil and type(drawing.data.Radius) == "number" and drawing.data.Radius> 0 and drawing.data.Radius or 16;

        if drawing.visible then
            -- Filled Circle
            local Main = AddDrawing("Circle", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex + 1 or 1;
                Transparency = drawing.data.FillTransparency ~= nil and type(drawing.data.FillTransparency) == "number" and drawing.data.FillTransparency >= 0 and drawing.data.FillTransparency <= 1 and drawing.data.FillTransparency or 1;
                Color = drawing.data.FillColor or drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Circle
                NumSides = drawing.data.NumSides ~= nil and type(drawing.data.NumSides) == "number" and drawing.data.NumSides > 0 and drawing.data.NumSides or 16;
                Radius = Radius;
                Position = Pos;
                Thickness = 1;
                Filled = drawing.data.Filled ~= nil and type(drawing.data.Filled) == "boolean" and drawing.data.Filled or false;
            })
            -- Outline Circle
            local Outline = AddDrawing("Circle", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Circle
                NumSides = drawing.data.NumSides ~= nil and type(drawing.data.NumSides) == "number" and drawing.data.NumSides > 0 and drawing.data.NumSides or 16;
                Radius = Radius;
                Position = Pos;
                Thickness = drawing.data.Thickness ~= nil and type(drawing.data.Thickness) == "number" and drawing.data.Thickness >= 0 or 3;
                Filled = false
            })
        end

        ScreenPoints = {
            Pos;
            Pos + Vector2.yAxis * Radius;
            Pos - Vector2.yAxis * Radius;
        }
    elseif drawing.type == DRAW_TYPES.CIRCLE_3D then
        local steps = drawing.data.NumSides ~= nil and type(drawing.data.NumSides) == "number" and drawing.data.NumSides > 0 and drawing.data.NumSides or 16
        local radius = drawing.data.Radius ~= nil and type(drawing.data.Radius) == "number" and drawing.data.Radius> 0 and drawing.data.Radius or 16
        local centerCFrame = drawing.data.CenterCFrame or CFrame.Angles(math.rad(90), 0, 0)

        for i = 0, steps - 1 do
            local angle_1 = (2 * PI * i) / steps
            local angle_2 = (2 * PI * (i + 1)) / steps

            -- Local-space circle points (XY plane)
            local p1_local = Vector3.new(math.cos(angle_1) * radius, math.sin(angle_1) * radius, 0)
            local p2_local = Vector3.new(math.cos(angle_2) * radius, math.sin(angle_2) * radius, 0)

            -- Rotate + translate using the CFrame
            local p1_world = centerCFrame * p1_local
            local p2_world = centerCFrame * p2_local

            -- Project to screen
            local screen1 = Camera:WorldToViewportPoint(p1_world)
            table.insert(ScreenPoints, Vector2.new(screen1.X, screen1.Y))
            local screen2 = Camera:WorldToViewportPoint(p2_world)

            if screen1 and screen2 and drawing.visible then
                local line = AddDrawing("Line", {
                    --BaseDrawingObject
                    Visible = true;
                    ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
                    Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                    Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                    --Line
                    From = screen1;
                    To = screen2;
                    Thickness = drawing.data.Thickness or 1;
                })
            end
        end
    elseif drawing.type == DRAW_TYPES.LINE_2D then
        local Pos1, Pos2 = drawing.data.Pos1, drawing.data.Pos2
        assert(Pos1 and typeof(Pos1) == "Vector2", "[ERROR] drawing.data.Pos1 must be a Vector2!")
        assert(Pos2 and typeof(Pos2) == "Vector2", "[ERROR] drawing.data.Pos2 must be a Vector2!")

        if drawing.visible then
            local line = AddDrawing("Line", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Line
                From = Pos1;
                To = Pos2;
                Thickness = drawing.data.Thickness or 1;
            })
        end

        ScreenPoints = {Pos1, Pos2}
    elseif drawing.type == DRAW_TYPES.LINE_3D then
        local Pos1, Pos2 = drawing.data.Pos1, drawing.data.Pos2
        assert(Pos1 and typeof(Pos1) == "Vector3", "[ERROR] drawing.data.Pos1 must be a Vector3!")
        assert(Pos2 and typeof(Pos2) == "Vector3", "[ERROR] drawing.data.Pos2 must be a Vector3!")

        -- Project to screen
        local screen1 = Camera:WorldToViewportPoint(Pos1)
        local screen2 = Camera:WorldToViewportPoint(Pos2)

        if drawing.visible then
            local line = AddDrawing("Line", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Line
                From = screen1;
                To = screen2;
                Thickness = drawing.data.Thickness or 1;
            })
        end

        ScreenPoints = {screen1, screen2}
    elseif drawing.type == DRAW_TYPES.TEXT then
        local Pos, TextBounds = drawing.data.Pos, drawing.data.TextBounds
        assert(Pos and typeof(Pos) == "Vector2", "[ERROR] drawing.data.Pos must be a Vector2!")
        assert(TextBounds and typeof(TextBounds) == "Vector2", "[ERROR] drawing.data.Size must be a Vector2!")

        if drawing.visible then
            local text = AddDrawing("Text", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Text
                Text = drawing.data.Text ~= nil and type(drawing.data.Text) == "string" and drawing.data.Text or "";
                TextBounds = TextBounds;
                Font = drawing.data.Font ~= nil and type(drawing.data.Font) == "number" and drawing.data.Font >= 0 and drawing.data.Font <= 3 and drawing.data.Font or FONTS.UI;
                Size = drawing.data.FontSize ~= nil and type(drawing.data.FontSize) == "number" and drawing.data.FontSize > 0 and drawing.data.FontSize or 12;
                Position = Pos;
                Center = drawing.data.Center ~= nil and type(drawing.data.Center) == "boolean" and drawing.data.Center or true;
                Outline = drawing.data.Outline ~= nil and type(drawing.data.Outline) == "boolean" and drawing.data.Outline or false;
                OutlineColor = drawing.data.OutlineColor ~= nil and typeof(drawing.data.OutlineColor) == "Color3" and drawing.data.OutlineColor or Color3.new(0,0,0);
            })
        end
        
        ScreenPoints = {
            Pos + Vector2.new(-TextBounds.X/2, -TextBounds.X/2);
            Pos + Vector2.new(-TextBounds.X/2, TextBounds.X/2);
            Pos + Vector2.new(TextBounds.X/2, TextBounds.X/2);
            Pos + Vector2.new(TextBounds.X/2, -TextBounds.X/2);
        }
    end

    if drawing.tracer ~= nil and type(drawing.tracer) == "table" then
        local TracerAnchors = GetTracerAnchors(ScreenPoints)
        local origin = drawing.tracer.origin ~= nil and type(drawing.tracer.origin) == "string" and drawing.tracer.origin or TRACER_ORIGINS.MOUSE;
        local target = drawing.tracer.target ~= nil and type(drawing.tracer.target) == "string" and drawing.tracer.target or TRACER_TARGETS.CENTER;
        local color = drawing.tracer.color ~= nil and typeof(drawing.tracer.color) == "Color3" and drawing.tracer.color or drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);

        local originPos: Vector2
        local targetPos: Vector2

        if origin == TRACER_ORIGINS.MOUSE then
            originPos = UserInputService:GetMouseLocation()
        else
            local ViewportSize = Camera.ViewportSize
            local Center = Vector2.new(ViewportSize.X/2, ViewportSize.Y/2)
            if origin == TRACER_ORIGINS.CENTER then
                originPos = Center
            elseif origin == TRACER_ORIGINS.BOTTOM then
                originPos = Center + Vector2.yAxis * ViewportSize.Y * 0.8;
            elseif origin == TRACER_ORIGINS.TOP then
                originPos = Center - Vector2.yAxis * ViewportSize.Y * 0.8;
            end
        end

        if target == TRACER_TARGETS.CENTER then
            targetPos = TracerAnchors.Center
        elseif target == TRACER_TARGETS.BOTTOM then
            targetPos = TracerAnchors.Bottom
        elseif target == TRACER_TARGETS.TOP then
            targetPos = TracerAnchors.Top
        end

        local tracer = AddDrawing("Line", {
            --BaseDrawingObject
            Visible = true;
            ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 0;
            Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
            Color = color;
            --Line
            From = originPos;
            To = targetPos;
            Thickness = drawing.data.Thickness or 1;
        })
    end
    
    drawing.ScreenPoints = ScreenPoints

    return drawing
end

-- Add drawing to library
function ESP:addDrawing(drawType, properties)
    local drawing = CreateDrawing(drawType, properties)
    return drawing
end

-- Create 3D box
function ESP:createBox3D(properties)
    return self:addDrawing(DRAW_TYPES.BOX_3D, properties)
end

-- Create 2D rectangle
function ESP:createRect2D(properties)
    return self:addDrawing(DRAW_TYPES.RECT_2D, properties)
end

-- Create 3D rectangle
function ESP:createRect3D(properties)
    return self:addDrawing(DRAW_TYPES.RECT_3D, properties)
end

-- Create 2D circle
function ESP:createCircle2D(properties)
    return self:addDrawing(DRAW_TYPES.CIRCLE_2D, properties)
end

-- Create 3D circle
function ESP:createCircle3D(properties)
    return self:addDrawing(DRAW_TYPES.CIRCLE_3D, properties)
end

-- Create 2D line
function ESP:createLine2D(properties)
    return self:addDrawing(DRAW_TYPES.LINE_2D, properties)
end

-- Create 3D line
function ESP:createLine3D(properties)
    return self:addDrawing(DRAW_TYPES.LINE_3D, properties)
end

-- Create text box
function ESP:createText(properties)
    return self:addDrawing(DRAW_TYPES.TEXT, properties)
end

-- Clear all drawings
function ESP:clear()
    cleardrawcache()
end

-- Render all visible drawings (calls user-defined render functions)
function ESP:render(doDrawings)
    self:clear()
    if doDrawings and type(doDrawings) == "function" then
        doDrawings()
    end
end

genv.ESP = ESP
return ESP