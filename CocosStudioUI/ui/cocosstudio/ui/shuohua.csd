<GameFile>
  <PropertyGroup Name="shuohua" Type="Node" ID="b4287e03-b78b-45fd-83ae-72f570a42e0b" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="20" Speed="0.2500" ActivedAnimationName="shuohua">
        <Timeline ActionTag="888909942" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="ui/qj_yuyin/yuyin0.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="5" Tween="False">
            <TextureFile Type="Normal" Path="ui/qj_yuyin/yuyin1.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="10" Tween="False">
            <TextureFile Type="Normal" Path="ui/qj_yuyin/yuyin2.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="15" Tween="False">
            <TextureFile Type="Normal" Path="ui/qj_yuyin/yuyin3.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="20" Tween="False">
            <TextureFile Type="Normal" Path="ui/qj_yuyin/yuyin3.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="888909942" Property="BlendFunc">
          <BlendFuncFrame FrameIndex="0" Tween="False" Src="1" Dst="771" />
          <BlendFuncFrame FrameIndex="5" Tween="False" Src="1" Dst="771" />
          <BlendFuncFrame FrameIndex="10" Tween="False" Src="1" Dst="771" />
          <BlendFuncFrame FrameIndex="15" Tween="False" Src="1" Dst="771" />
          <BlendFuncFrame FrameIndex="20" Tween="False" Src="1" Dst="771" />
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="shuohua" StartIndex="0" EndIndex="20">
          <RenderColor A="255" R="139" G="0" B="0" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="829" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="Panel_1" ActionTag="1741632272" Tag="830" IconVisible="False" RightMargin="-300.0000" TopMargin="-5.0000" BottomMargin="-55.0000" ClipAble="False" BackColorAlpha="102" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" ctype="PanelObjectData">
            <Size X="300.0000" Y="60.0000" />
            <Children>
              <AbstractNodeData Name="Image_1" ActionTag="1215070257" Tag="831" IconVisible="False" FlipX="True" Scale9Enable="True" LeftEage="30" RightEage="30" TopEage="15" BottomEage="15" Scale9OriginX="30" Scale9OriginY="15" Scale9Width="42" Scale9Height="30" ctype="ImageViewObjectData">
                <Size X="300.0000" Y="60.0000" />
                <Children>
                  <AbstractNodeData Name="Sprite_1" ActionTag="888909942" Tag="581" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="228.5000" RightMargin="48.5000" TopMargin="15.0000" BottomMargin="15.0000" FlipX="True" ctype="SpriteObjectData">
                    <Size X="23.0000" Y="30.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="240.0000" Y="30.0000" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition X="0.8000" Y="0.5000" />
                    <PreSize X="0.0767" Y="0.5000" />
                    <FileData Type="Normal" Path="ui/qj_yuyin/yuyin0.png" Plist="" />
                    <BlendFunc Src="1" Dst="771" />
                  </AbstractNodeData>
                </Children>
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="150.0000" Y="30.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.5000" Y="0.5000" />
                <PreSize X="1.0000" Y="1.0000" />
                <FileData Type="Normal" Path="ui/qj_play/qipao.png" Plist="" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position Y="-55.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <SingleColor A="255" R="150" G="200" B="255" />
            <FirstColor A="255" R="150" G="200" B="255" />
            <EndColor A="255" R="255" G="255" B="255" />
            <ColorVector ScaleY="1.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="Panel_2" ActionTag="149755114" Tag="833" IconVisible="False" RightMargin="-300.0000" TopMargin="-5.0000" BottomMargin="-55.0000" TouchEnable="True" ClipAble="False" BackColorAlpha="102" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" ctype="PanelObjectData">
            <Size X="300.0000" Y="60.0000" />
            <Children>
              <AbstractNodeData Name="Text_1" ActionTag="-2120019030" Tag="198" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="108.5000" RightMargin="108.5000" TopMargin="18.5000" BottomMargin="18.5000" FontSize="20" LabelText="正在说话" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="TextObjectData">
                <Size X="83.0000" Y="23.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="150.0000" Y="30.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="17" G="31" B="110" />
                <PrePosition X="0.5000" Y="0.5000" />
                <PreSize X="0.2767" Y="0.3833" />
                <FontResource Type="Normal" Path="ui/zhunyuan.ttf" Plist="" />
                <OutlineColor A="255" R="255" G="0" B="0" />
                <ShadowColor A="255" R="110" G="110" B="110" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position Y="-55.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
            <SingleColor A="255" R="150" G="200" B="255" />
            <FirstColor A="255" R="150" G="200" B="255" />
            <EndColor A="255" R="255" G="255" B="255" />
            <ColorVector ScaleY="1.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>