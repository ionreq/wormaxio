/' endlich ein gescheites wormaxio


	gemacht
		beschleunigung
		drehrate
		smoothing
		konstanter abstand glieder
		muster auf gliedern
		schwanzende sauber abschließen

	todo
		gegner
		rand
		kollision
		opengl
		futter
		unterschiedliche größe
		zoom
		wachsen

'/

#Include "windows.bi"


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
Const RR = 25			' Radius Glied
Const DG = 0.003		' Drehgeschwindigkeit
Const GA = 17			' Abstand Glieder

Declare Sub main
main
End


Sub main()
	Dim As Double vx, vy, d, va, wx, wy, wa, a, b, cx(NP), cy(NP), ox, oy, ex, ey
	Dim As Integer v
	Dim As Integer mx, my, wheel, button
	Dim As Integer e, t, n, l
	Dim As Double px(NP), py(NP), ux(NP), uy(NP), dd, dc, c
	Dim As Single hx(NH), hy(NH)
	Dim As Double tim
	Dim As String i


	ScreenRes SX,SY,32,2,1
	ScreenSet 1,0
	Color RGB(255,255,255),RGB(0,0,0)

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

		Cls
		GetMouse mx, my, wheel, button

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


		For t = 0 To NH										' Hintergrund zeichnen
			PSet(SX/2-px(0)+hx(t),SY/2-py(0)+hy(t))
		Next
		Circle(SX/2-px(0),SY/2-py(0)),HR


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

		For t = e To 0 Step -1				' Glieder zeichnen
			Circle(SX/2-px(0)+cx(t), SY/2-py(0)+cy(t)),RR,RGB(255,128,0),,,,F
			Circle(SX/2-px(0)+cx(t), SY/2-py(0)+cy(t)),RR,RGB(255,0,0)
			If t>0 Then
				ex = cx(t-1)-cx(t)
				ey = cy(t-1)-cy(t)
				d = Sqr(ex^2+ey^2)
				ex /= d
				ey /= d
				Line(SX/2-px(0)+cx(t),SY/2-py(0)+cy(t))-(SX/2-px(0)+cx(t)-ex*RR*0.9,SY/2-py(0)+cy(t)-ey*RR*0.9)
			EndIf
		Next

		Line(SX/2,SY/2)-(SX/2+wx*RR,SY/2+wy*RR),RGB(255,255,0)		' Drehwinkel Linien
		Line(SX/2,SY/2)-(SX/2+vx*RR,SY/2+vy*RR)


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


		Print Using "###.###";(Timer-tim)*1000

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

		ScreenCopy
		ScreenSync
	Loop

End Sub
