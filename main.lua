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

function GetScreenBounds(points)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for _, p in pairs(points) do
        if p.X < minX then minX = p.X end
        if p.Y < minY then minY = p.Y end
        if p.X > maxX then maxX = p.X end
        if p.Y > maxY then maxY = p.Y end
    end

    return minX, minY, maxX, maxY
end

function GetRect2DAnchors(points)
    local minX, minY, maxX, maxY = GetScreenBounds(points)

    local centerX = (minX + maxX) * 0.5
    local centerY = (minY + maxY) * 0.5

    return {
        Center = Vector2.new(centerX, centerY);

        TopLeft = Vector2.new(minX, maxY);
        Top = Vector2.new(centerX, maxY);
        TopRight = Vector2.new(maxX, maxY);

        BottomLeft = Vector2.new(minX, minY);
        Bottom = Vector2.new(centerX, minY);
        BottomRight = Vector2.new(maxX, minY);

        Left = Vector2.new(minX, centerY);
        Right = Vector2.new(maxX, centerY);
    }
end

function GetBox3DCorners(cf: CFrame, size: Vector3)
    local Camera = workspace.CurrentCamera
    local hx, hy, hz = size.X/2, size.Y/2, size.Z/2

    local offsets = {
        [1] = Vector3.new(-hx, -hy, -hz),
        [2] = Vector3.new(-hx, -hy,  hz),
        [3] = Vector3.new(-hx,  hy, -hz),
        [4] = Vector3.new(-hx,  hy,  hz),

        [5] = Vector3.new( hx, -hy, -hz),
        [6] = Vector3.new( hx, -hy,  hz),
        [7] = Vector3.new( hx,  hy, -hz),
        [8] = Vector3.new( hx,  hy,  hz),
    }

    local corners = {}
    for i = 1, 8 do
        corners[i] = cf * offsets[i]
    end

    -- Project all corners
    local projected = {}
    for i, corner in ipairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
        -- if not onScreen then
        --     -- If ANY corner is off-screen, you can choose to skip drawing
        --     -- or clamp it. For now, we skip.
        --     return
        -- end
        projected[i] = Vector2.new(screenPos.X, screenPos.Y)
    end

    return projected
end

function GetRectCorners(cf: CFrame, size: Vector3)
    local Camera = workspace.CurrentCamera
    local hx, hy = size.X/2, size.Y/2

    local offsets = {
        BottomLeft = Vector3.new(-hx, -hy, 0); -- bottom-left
        BottomRight = Vector3.new( hx, -hy, 0); -- bottom-right
        TopRight = Vector3.new( hx,  hy, 0); -- top-right
        TopLeft = Vector3.new(-hx,  hy, 0); -- top-left
    }

    local corners = {}
    for i, offset in pairs(offsets) do
        corners[i] = cf * offset
    end

    -- Project all corners
    local projected = {}
    for i, corner in pairs(corners) do
        local screenPos, onScreen = Camera:WorldToViewportPoint(corner)
        -- if not onScreen then
        --     -- If ANY corner is off-screen, you can choose to skip drawing
        --     -- or clamp it. For now, we skip.
        --     return
        -- end
        projected[i] = Vector2.new(screenPos.X, screenPos.Y)
    end

    return projected
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
	
    local CornerTable = GetRectCorners(CF, Size)
	
	local ViewportPoint, OnScreen = Camera:WorldToViewportPoint(CF.Position)

    local Anchors = GetRect2DAnchors(CornerTable)
	local ScreenSize = Vector2.new((Anchors.Right - Anchors.Left).Magnitude, (Anchors.Bottom - Anchors.Top).Magnitude)
    local ScreenPosition = Anchors.Center

	return {
        CF = CF;
        Size = Size;
        ViewportPoint = ViewportPoint;
		ScreenPosition = ScreenPosition;
		ScreenSize = ScreenSize;
		OnScreen = OnScreen;
        ScreenPoints = CornerTable;
        Anchors = Anchors;
	}
end
ESP.CalculateRect2D = CalculateRect2D

function CalculateRect3D(object: BasePart|Model)
    if not object then return end
    local CF, Size
    if object:IsA("Model") then
        CF = object.PrimaryPart and object.PrimaryPart.CFrame or object:GetPivot() or nil
        Size = object:GetExtentsSize()
        if not CF then
            CF, Size = object:GetBoundingBox()
        end
    elseif object:IsA("BasePart") then
        CF = object.CFrame
        Size = object.Size
    end
	local Camera = workspace.CurrentCamera

    local CornerTable = GetRectCorners(CF, Size)
	
	local ViewportPoint, OnScreen = Camera:WorldToViewportPoint(CF.Position)

    local Anchors = GetRect2DAnchors(CornerTable)
	local ScreenSize = Vector2.new((Anchors.Right - Anchors.Left).Magnitude, (Anchors.Bottom - Anchors.Top).Magnitude)
    local ScreenPosition = Anchors.Center

	return {
        CF = CF;
        Size = Size;
        ViewportPoint = ViewportPoint;
		ScreenPosition = ScreenPosition;
		ScreenSize = ScreenSize;
		OnScreen = OnScreen;
        ScreenPoints = CornerTable;
        Anchors = Anchors;
	}
end
ESP.CalculateRect3D = CalculateRect3D

function CalculateBox3D(object: BasePart|Model)
    if not object then return end
    local rect3dCalculations = CalculateRect3D(object)

    local CornerTable = GetBox3DCorners(rect3dCalculations.CF, rect3dCalculations.Size)
    local Anchors = GetRect2DAnchors(CornerTable)
	local ScreenSize = Vector2.new((Anchors.Right - Anchors.Left).Magnitude, (Anchors.Bottom - Anchors.Top).Magnitude)
    local ScreenPosition = Anchors.Center

    rect3dCalculations.ScreenPosition = ScreenPosition
    rect3dCalculations.ScreenSize = ScreenSize
    rect3dCalculations.ScreenPoints = CornerTable
    rect3dCalculations.Anchors = Anchors

    return rect3dCalculations
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
    {1,3,4,2}, -- Left
    {5,6,8,7}, -- Right
    {1,2,6,5}, -- Bottom
    {3,7,8,4}, -- Top
    {1,5,7,3}, -- Front
    {2,4,8,6}, -- Back
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
    return crossZ > 0 -- positive = facing camera (completely based on winding order)
end

function CountList(list)
    local count = 0
    for _, _ in pairs(list) do
        count += 1
    end
    return count
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
        local BoxCorners = drawing.data.ScreenPoints
        assert(BoxCorners and type(BoxCorners) == "table", "[ERROR] BoxCorners must be a table!")
        assert(CountList(BoxCorners) == 8, "[ERROR] BoxCorners must have 8 corners!")
        for i, v in pairs(BoxCorners) do
            assert(v and typeof(v) == "Vector2", "[ERROR] BoxCorners["..tostring(i).."] must be a Vector2!")
        end

        ScreenPoints = BoxCorners

        if drawing.visible then
            -- Draw visible faces
            for _, face in ipairs(BOX_3D_FACES) do
                local A = ScreenPoints[face[1]]
                local B = ScreenPoints[face[2]]
                local C = ScreenPoints[face[3]]
                local D = ScreenPoints[face[4]]
                local QuadCorners = {A, B, C, D}
                -- Cull backfaces
                if IsFaceVisible(A, B, C) then
                    -- Filled Quad
                    local Main = AddDrawing("Quad", {
                        --BaseDrawingObject
                        Visible = true;
                        ZIndex = (drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 1);
                        Transparency = drawing.data.FillTransparency ~= nil and type(drawing.data.FillTransparency) == "number" and drawing.data.FillTransparency >= 0 and drawing.data.FillTransparency <= 1 and drawing.data.FillTransparency or 1;
                        Color = drawing.data.FillColor or drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                        --Quad
                        PointA = A;
                        PointB = B;
                        PointC = C;
                        PointD = D;
                        Filled = drawing.data.Filled ~= nil and type(drawing.data.Filled) == "boolean" and drawing.data.Filled or false;
                        Thickness = 1;
                    })
                end
                -- Outline Quad
                local Outline = AddDrawing("Quad", {
                    --BaseDrawingObject
                    Visible = true;
                    ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex + 1 or 2;
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
    elseif drawing.type == DRAW_TYPES.RECT_2D then
        local Pos, Size, RectCorners = drawing.data.Pos, drawing.data.Size, drawing.data.ScreenPoints
        assert(Pos and typeof(Pos) == "Vector2", "[ERROR] drawing.data.Pos must be a Vector2!")
        assert(Size and typeof(Size) == "Vector2", "[ERROR] drawing.data.Size must be a Vector2!")
        assert(RectCorners and type(RectCorners) == "table", "[ERROR] RectCorners must be a table!")
        assert(CountList(RectCorners) == 4, "[ERROR] RectCorners must have 4 corners!")
        for i, v in pairs(RectCorners) do
            assert(v and typeof(v) == "Vector2", "[ERROR] RectCorners["..tostring(i).."] must be a Vector2!")
        end

        ScreenPoints = RectCorners

        if drawing.visible then
            -- Filled Square
            local Main = AddDrawing("Square", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 1;
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
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex + 1 or 2;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Square
                Size = Size;
                Position = Pos;
                Thickness = drawing.data.Thickness ~= nil and type(drawing.data.Thickness) == "number" and drawing.data.Thickness >= 0 or 3;
                Filled = false;
            })
        end
    elseif drawing.type == DRAW_TYPES.RECT_3D then
        local QuadCorners = drawing.data.ScreenPoints
        assert(QuadCorners and type(QuadCorners) == "table", "[ERROR] QuadCorners must be a table!")
        assert(CountList(QuadCorners) == 4, "[ERROR] QuadCorners must be have to 4 corners!")
        for i, v in pairs(QuadCorners) do
            assert(v and typeof(v) == "Vector2", "[ERROR] QuadCorners["..tostring(i).."] must be a Vector2!")
        end

        ScreenPoints = QuadCorners

        if drawing.visible then
            -- Filled Quad
            local Main = AddDrawing("Quad", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 1;
                Transparency = drawing.data.FillTransparency ~= nil and type(drawing.data.FillTransparency) == "number" and drawing.data.FillTransparency >= 0 and drawing.data.FillTransparency <= 1 and drawing.data.FillTransparency or 1;
                Color = drawing.data.FillColor or drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Quad
                PointA = ScreenPoints.TopLeft;
                PointB = ScreenPoints.TopRight;
                PointC = ScreenPoints.BottomRight;
                PointD = ScreenPoints.BottomLeft;
                Thickness = 1;
                Filled = drawing.data.Filled ~= nil and type(drawing.data.Filled) == "boolean" and drawing.data.Filled or false;
            })
            -- Outline Quad
            local Outline = AddDrawing("Quad", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex + 1 or 2;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
                --Quad
                PointA = ScreenPoints.TopLeft;
                PointB = ScreenPoints.TopRight;
                PointC = ScreenPoints.BottomRight;
                PointD = ScreenPoints.BottomLeft;
                Thickness = drawing.data.Thickness ~= nil and type(drawing.data.Thickness) == "number" and drawing.data.Thickness >= 0 or 3;
                Filled = false;
            })
        end
    elseif drawing.type == DRAW_TYPES.CIRCLE_2D then
        local Pos = drawing.data.CenterPos
        assert(Pos and typeof(Pos) == "Vector2", "[ERROR] drawing.data.CenterPos must be a Vector2!")
        local Radius = drawing.data.Radius ~= nil and type(drawing.data.Radius) == "number" and drawing.data.Radius> 0 and drawing.data.Radius or 16;

        if drawing.visible then
            -- Filled Circle
            local Main = AddDrawing("Circle", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 1;
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
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex + 1 or 2;
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
                    ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 2;
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
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 2;
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
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 2;
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
        local Pos = drawing.data.Pos
        assert(Pos and typeof(Pos) == "Vector2", "[ERROR] drawing.data.Pos must be a Vector2!")

        if drawing.visible then
            local text = Drawing.new("Text")
            text.Visible = true;
            text.Center = drawing.data.Center ~= nil and type(drawing.data.Center) == "boolean" and drawing.data.Center or true;
            text.Outline = drawing.data.Outline ~= nil and type(drawing.data.Outline) == "boolean" and drawing.data.Outline or true;
            text.Font = drawing.data.Font ~= nil and type(drawing.data.Font) == "number" and drawing.data.Font >= 0 and drawing.data.Font <= 3 and drawing.data.Font or FONTS.Plex;
            text.Size = drawing.data.FontSize ~= nil and type(drawing.data.FontSize) == "number" and drawing.data.FontSize > 0 and drawing.data.FontSize or 14;
            text.ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 3;
            text.Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
            text.Color = drawing.color ~= nil and typeof(drawing.color) == "Color3" and drawing.color or Color3.new(1,1,1);
            text.OutlineColor = drawing.data.OutlineColor ~= nil and typeof(drawing.data.OutlineColor) == "Color3" and drawing.data.OutlineColor or Color3.new();
            text.Text = drawing.data.Text ~= nil and type(drawing.data.Text) == "string" and drawing.data.Text or "";
            print("CHECK 1")
            print("text.Text", text.Text)
            print("text.Font", text.Font)
            print("text.TextBounds", text.TextBounds)
            print("text.Position", text.Position)
            print("text.Size", text.Size)
            print("CHECK 2")
            print("text.Visible", text.Visible)
            print("text.Center", text.Center)
            print("text.Outline", text.Outline)
            print("text.OutlineColor", text.OutlineColor)
            print("text.Transparency", text.Transparency)
            print("text.ZIndex", text.ZIndex)
            print("text.Color", text.Color)
            print("CHECK 3")

            text.Position = Pos;

            ScreenPoints = {
                Pos + Vector2.new(-text.TextBounds.X/2, -text.TextBounds.X/2);
                Pos + Vector2.new(-text.TextBounds.X/2, text.TextBounds.X/2);
                Pos + Vector2.new(text.TextBounds.X/2, text.TextBounds.X/2);
                Pos + Vector2.new(text.TextBounds.X/2, -text.TextBounds.X/2);
            }
        end
    end

    if ScreenPoints then
        drawing.ScreenPoints = ScreenPoints
        drawing.Anchors = drawing.data.Anchors or GetRect2DAnchors(ScreenPoints)

        if drawing.tracer ~= nil and type(drawing.tracer) == "table" then
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
                targetPos = drawing.Anchors.Center
            elseif target == TRACER_TARGETS.BOTTOM then
                targetPos = drawing.Anchors.Bottom
            elseif target == TRACER_TARGETS.TOP then
                targetPos = drawing.Anchors.Top
            end

            local tracer = AddDrawing("Line", {
                --BaseDrawingObject
                Visible = true;
                ZIndex = drawing.data.ZIndex ~= nil and type(drawing.data.ZIndex) == "number" and drawing.data.ZIndex or 2;
                Transparency = drawing.data.Transparency ~= nil and type(drawing.data.Transparency) == "number" and drawing.data.Transparency >= 0 and drawing.data.Transparency <= 1 and drawing.data.Transparency or 0;
                Color = color;
                --Line
                From = originPos;
                To = targetPos;
                Thickness = drawing.data.Thickness or 1;
            })
        end
    end

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
    -- cleardrawcache()
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