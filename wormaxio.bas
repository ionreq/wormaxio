/' endlich ein gescheites wormaxio


	gemacht
		beschleunigung
		drehrate
		smoothing
		konstanter abstand glieder
		muster auf gliedern
		schwanzende sauber abschließen
		opengl
		texturen

	todo
		gegner
		rand
		kollision
		futter
		unterschiedliche größe
		zoom
		wachsen
		sinusförmig atmen

'/

#Include "windows.bi"
#Include "fbgfx.bi"
#Include "gl/gl.bi"
#Include "gl/glu.bi"
#Include "gl/glut.bi"
#Include "string.bi"


Const PI = 6.2831853

Const SX = 1366
Const SY = 768
'Const SX = 800
'Const SY = 600

Const HR = 3000		' Hintergrund Kreis Radius
Const NH = 1000		' Anzahl Punkte Hintergrund
Const V1 = 4			' langsame Geschwindigkeit
Const V2 = 10			' schnelle Geschwindigkeit
Const NS = 4			' Anzahl Smooth Glieder
Const NP = 3000		' Anzahl Punkte Schlange
Const RR = 45			' Radius Glied
Const DG = 0.003		' Drehgeschwindigkeit
Const GA = 2*RR/3			' Abstand Glieder


Dim Shared As UByte Ptr mtex_body, mtex_head


Declare Sub main
main
End


Sub loadtextures ()
	Dim As UByte a(54),r,g,b
	Dim As Integer t
	Dim As UByte Ptr m

	m = mtex_body
	Open "body.bmp" For Binary Access Read As #1
	Get #1,,a(1),54
	For t = 1 To 64*64
		Get #1,,b,1
		Get #1,,g,1
		Get #1,,r,1
		*m = r : m += 1
		*m = g : m += 1
		*m = b : m += 1
		If r=255 And g=255 And b=255 Then *m = 0 Else *m = 255
		m += 1
	Next
	Close #1

	m = mtex_head
	Open "head.bmp" For Binary Access Read As #1
	Get #1,,a(1),54
	For t = 1 To 64*64
		Get #1,,b,1
		Get #1,,g,1
		Get #1,,r,1
		*m = r : m += 1
		*m = g : m += 1
		*m = b : m += 1
		If r=255 And g=255 And b=255 Then *m = 0 Else *m = 255
		m += 1
	Next
	Close #1

End Sub




Sub mytextout (x As Double, y As Double, z As Double, s As String)
	glRasterPos3d (x, y, z)
	glListBase (1000)
	glCallLists (Len(s), GL_UNSIGNED_BYTE, StrPtr(s))
End Sub


Sub main()
	Dim As Double vx, vy, d, va, wx, wy, wa, a, b
	Dim As Double cx(NP), cy(NP), ox, oy, ex, ey, fx, fy
	Dim As Integer v
	Dim As Integer mx, my, wheel, button
	Dim As Integer e, t, n, l
	Dim As Double px(NP), py(NP), ux(NP), uy(NP), dd, dc, c
	Dim As Single hx(NH), hy(NH)
	Dim As Double tim
	Dim As String i
	Dim As HWND hwnd
	Dim As HDC hdc
	Dim As HGLRC hglrc
	Dim As GLuint texture_body, texture_head


	ScreenRes SX,SY,32,,FB.GFX_FULLSCREEN+FB.GFX_OPENGL  '+FB.GFX_MULTISAMPLE  '+FB.GFX_ALPHA_PRIMITIVES

	ScreenControl (FB.GET_WINDOW_HANDLE, Cast (Integer, hwnd))
	hdc = GetDC (hwnd)
	hglrc = wglCreateContext (hdc)
	wglMakeCurrent (hdc, hglrc)
	SelectObject (hdc, GetStockObject (SYSTEM_FONT))
	wglUseFontBitmaps (hdc, 0, 255, 1000)

	' turn vertical sync off (otherwise it is on by default)
	'Dim SwapInterval As Function (ByVal interval As Integer) As Integer
	'SwapInterval = ScreenGLProc ("wglSwapIntervalEXT")
	'SwapInterval (0)

	glViewport (0, 0, SX, SY)
	glMatrixMode (GL_PROJECTION)
	glLoadIdentity ()
	glOrtho (0, SX, 0, SY, -1, 1)
	glMatrixMode (GL_MODELVIEW)
	glLoadIdentity ()

	glClearColor (0, 0, 0, 1)		' background color
	'glEnable (GL_DEPTH_TEST)
	glEnable (GL_TEXTURE_2D)
	glEnable (GL_BLEND)
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

	mtex_body = Allocate (64*64*4)
	mtex_head = Allocate (64*64*4)
	
	loadtextures ()
	
	glGenTextures (1, @texture_body)
	glBindTexture (GL_TEXTURE_2D, texture_body)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
	glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, 64, 64, 0, GL_RGBA, GL_UNSIGNED_BYTE, mtex_body)

	glGenTextures (1, @texture_head)
	glBindTexture (GL_TEXTURE_2D, texture_head)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
	glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
	glTexImage2D (GL_TEXTURE_2D, 0, GL_RGBA, 64, 64, 0, GL_RGBA, GL_UNSIGNED_BYTE, mtex_head)
	

	For t = 0 To NH
		Do
			hx(t) = (Rnd*2-1)*HR
			hy(t) = (Rnd*2-1)*HR
		Loop While Sqr(hx(t)^2+hy(t)^2)>=HR
	Next


	For t = 0 To NP
		px(t) = t
		py(t) = 0
	Next


	Do
		tim = Timer

		glClear (GL_COLOR_BUFFER_BIT + GL_DEPTH_BUFFER_BIT)

		GetMouse mx, my, wheel, button

		my = SY-1-my

		mx -= SX/2
		my -= SY/2

		vx = mx					' Mauswinkel
		vy = my
		d = Sqr(vx^2+vy^2)
		If d=0 Then
			vx = 0
			vy = 0
		Else
			vx /= d
			vy /= d
		EndIf
		va = Atan2(vy,vx)

		a = vx*wy - vy*wx			' Drehwinkel Wurm berechnen
		If a<0 Then
			wa += PI*DG*v
			wx = Cos(wa)
			wy = Sin(wa)
			b = vx*wy - vy*wx
			If b>0 Then wa = va
		EndIf
		If a>0 Then
			wa -= PI*DG*v
			wx = Cos(wa)
			wy = Sin(wa)
			b = vx*wy - vy*wx
			If b<0 Then wa = va
		EndIf
		wx = Cos(wa)
		wy = Sin(wa)

		glColor4d (1,1,1,1)
		glBegin (GL_POINTS)
		For t = 0 To NH										' Hintergrund zeichnen
			glVertex2d (SX/2-px(0)+hx(t),SY/2-py(0)+hy(t))
		Next
		glEnd ()
		'Circle(SX/2-px(0),SY/2-py(0)),HR


		e = 0					' Gliedkoos berechnen
		cx(e) = px(0)
		cy(e) = py(0)
		dd = 0
		For t = 0 To NP-1
			dc = Sqr((px(t+1)-px(t))^2+(py(t+1)-py(t))^2)
			dd += dc
			If dd>GA Then
				dd -= GA
				c = 1-dd/dc
				e += 1
				cx(e) = c*px(t+1) + (1-c)*px(t)
				cy(e) = c*py(t+1) + (1-c)*py(t)
			EndIf
		Next
		e += 1
		cx(e) = px(NP)
		cy(e) = py(NP)


		glEnable (GL_TEXTURE_2D)
		glEnable (GL_BLEND)

		glBindTexture (GL_TEXTURE_2D, texture_body)

		For t = e To 1 Step -1				' Glieder zeichnen
			If t=e Then
				ex = px(NP-1)-px(NP)
				ey = py(NP-1)-py(NP)
			Else
				ex = cx(t)-cx(t+1)
				ey = cy(t)-cy(t+1)
			EndIf
			d = Sqr(ex^2+ey^2)
			ex /= d
			ey /= d
			fx = -ey
			fy = ex
			glBegin (GL_QUADS)
			glTexCoord2d (1,0) : glVertex2d (SX/2-px(0)+cx(t)-RR*ex-RR*fx, SY/2-py(0)+cy(t)-RR*ey-RR*fy)
			glTexCoord2d (1,1) : glVertex2d (SX/2-px(0)+cx(t)+RR*ex-RR*fx, SY/2-py(0)+cy(t)+RR*ey-RR*fy)
			glTexCoord2d (0,1) : glVertex2d (SX/2-px(0)+cx(t)+RR*ex+RR*fx, SY/2-py(0)+cy(t)+RR*ey+RR*fy)
			glTexCoord2d (0,0) : glVertex2d (SX/2-px(0)+cx(t)-RR*ex+RR*fx, SY/2-py(0)+cy(t)-RR*ey+RR*fy)
			glEnd ()
		Next

		glBindTexture (GL_TEXTURE_2D, texture_head)
		
		ex = vx
		ey = vy
		fx = -ey
		fy = ex
		
		glBegin (GL_QUADS)
		glTexCoord2d (1,0) : glVertex2d (SX/2-px(0)+cx(t)-RR*ex-RR*fx, SY/2-py(0)+cy(t)-RR*ey-RR*fy)
		glTexCoord2d (1,1) : glVertex2d (SX/2-px(0)+cx(t)+RR*ex-RR*fx, SY/2-py(0)+cy(t)+RR*ey-RR*fy)
		glTexCoord2d (0,1) : glVertex2d (SX/2-px(0)+cx(t)+RR*ex+RR*fx, SY/2-py(0)+cy(t)+RR*ey+RR*fy)
		glTexCoord2d (0,0) : glVertex2d (SX/2-px(0)+cx(t)-RR*ex+RR*fx, SY/2-py(0)+cy(t)-RR*ey+RR*fy)
		glEnd ()

		'Line(SX/2,SY/2)-(SX/2+wx*RR,SY/2+wy*RR),RGB(255,255,0)		' Drehwinkel Linien
		'Line(SX/2,SY/2)-(SX/2+vx*RR,SY/2+vy*RR)

		'glColor3d (1,1,1)
		'glBegin (GL_LINES)
		'glVertex2d (SX/2,SY/2)
		'glVertex2d (SX/2+vx*RR,SY/2+vy*RR)
		'glEnd ()


		For n = 1 To v

			For t = NP To 1 Step -1			' Glieder bewegen
				px(t) = px(t-1)
				py(t) = py(t-1)
			Next

			px(0) += wx
			py(0) += wy

			For t = 0 To NP			' Glieder smoothen
				ux(t) = px(t)
				uy(t) = py(t)
			Next

			For t = NS To NP-NS
				ex = 0
				ey = 0
				For l = -NS To NS
					ex += px(t+l)
					ey += py(t+l)
				Next
				ux(t) = ex/(2*NS+1)
				uy(t) = ey/(2*NS+1)
			Next

			For t = 0 To NP
				px(t) = ux(t)
				py(t) = uy(t)
			Next

		Next


		glDisable (GL_BLEND)
		glDisable (GL_TEXTURE_2D)

		mytextout (20,20,0,Format((Timer-tim)*1000,"000.000"))

		If GetAsyncKeyState (VK_Q)<0 Or button=1 Then
			v += 1
			If v>V2 Then v = V2
		Else
			v -= 1
			If v<V1 Then v = V1
		EndIf
		If GetAsyncKeyState (VK_W)<0 Then v = 0

		i = InKey
		If i=Chr(27) Then Exit Do

		Flip
	Loop

End Sub
