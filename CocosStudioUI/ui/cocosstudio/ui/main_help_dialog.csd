<GameFile>
  <PropertyGroup Name="main_help_dialog" Type="Layer" ID="15c477cf-c6c5-4c52-9176-c323f72735a8" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="0" Speed="1.0000" />
      <ObjectData Name="Layer" Tag="189" ctype="GameLayerObjectData">
        <Size X="1280.0000" Y="720.0000" />
        <Children>
          <AbstractNodeData Name="bg" ActionTag="-312734358" Tag="62" IconVisible="False" LeftMargin="0.5000" RightMargin="0.5000" TopMargin="8.5000" BottomMargin="8.5000" ctype="SpriteObjectData">
            <Size X="1279.0000" Y="703.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="640.0000" Y="360.0000" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5000" Y="0.5000" />
            <PreSize X="0.9992" Y="0.9764" />
            <FileData Type="Normal" Path="ui/qj_commom/KK_m.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="btExit" ActionTag="-1613298719" Tag="253" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="1219.9653" RightMargin="6.0347" TopMargin="9.2880" BottomMargin="484.7120" TouchEnable="True" FontSize="14" Scale9Enable="True" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="24" Scale9Height="204" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="54.0000" Y="226.0000" />
            <AnchorPoint ScaleX="0.5002" ScaleY="1.0000" />
            <Position X="1246.9761" Y="710.7120" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.9742" Y="0.9871" />
            <PreSize X="0.0422" Y="0.3139" />
            <TextColor A="255" R="65" G="65" B="70" />
            <PressedFileData Type="Normal" Path="ui/qj_commom/SHUT-fs8.png" Plist="" />
            <NormalFileData Type="Normal" Path="ui/qj_commom/SHUT-fs8.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="sTitle" ActionTag="-1694035440" Tag="60" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="557.5000" RightMargin="557.5000" TopMargin="35.4840" BottomMargin="651.5160" ctype="SpriteObjectData">
            <Size X="165.0000" Y="33.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="640.0000" Y="668.0160" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.5000" Y="0.9278" />
            <PreSize X="0.1289" Y="0.0458" />
            <FileData Type="Normal" Path="ui/qj_commom/youxiwanfa.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="pnRight" ActionTag="-1568278612" Tag="61" IconVisible="True" HorizontalEdge="RightEdge" VerticalEdge="BothEdge" LeftMargin="771.4700" RightMargin="508.5300" TopMargin="383.9760" BottomMargin="336.0240" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="svHelp" ActionTag="-1427356142" Tag="300" IconVisible="False" LeftMargin="-378.5135" RightMargin="-414.4865" TopMargin="-263.0300" BottomMargin="-253.9700" TouchEnable="True" ClipAble="True" BackColorAlpha="102" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" IsBounceEnabled="True" ScrollDirectionType="Vertical" ctype="ScrollViewObjectData">
                <Size X="793.0000" Y="517.0000" />
                <Children>
                  <AbstractNodeData Name="tNote" ActionTag="-749436854" Tag="218" IconVisible="False" RightMargin="1268.0000" TopMargin="3.8900" BottomMargin="-803.8900" IsCustomSize="True" FontSize="25" LabelText="一、	用牌：&#xA;a)	标准用牌：1~9筒，1~9万，1~9条，各4张，共108张。&#xA;b)	带风：标准用牌加上东南西北中发白，共136张。&#xA;二、	定庄：&#xA;a)	首局房主为庄家。&#xA;b)	正常局数：谁胡牌，下局谁坐庄，流局时，庄家下家坐庄。&#xA;c)	1圈：庄家胡牌，庄家连庄，闲家胡牌，庄家下家坐庄，流局时，庄家连庄。&#xA;三、	游戏规则：&#xA;a)	动作：吃、碰、杠、胡。&#xA;b)	随机癞子：&#xA;1.	癞子充当任意牌，且不可与其他牌组合，进行吃碰杠等操作。&#xA;2.	癞子打出后不可被碰，可被杠，不可被点炮。&#xA;四、	胡牌牌型：&#xA;a)	平胡：4个顺子/刻字/碰/杠+1对牌。&#xA;b)	七对：7个对子。&#xA;c)	十三幺：1-9筒，1-9万，1-9条，东南西北中发白，再加上以上任意一张牌。&#xA;五、	胡牌方式：&#xA;a)	接炮：所胡牌由他人打出，可过，可一炮多响。&#xA;b)	自摸：所胡牌由自己摸出，可过。&#xA;c)	抢杠：玩家进行明杠，有玩家能胡此张牌，可过。&#xA;六、	计分规则：&#xA;a)	计分公式：基础分+牌型分+杠分。&#xA;b)	2人基础分带庄闲：&#xA;1.	庄家接炮：闲家-4分。&#xA;2.	庄家自摸：闲家-4分。&#xA;3.	闲家接炮：庄家-4分。&#xA;4.	闲家自摸：庄家-4分。&#xA;c)	2人基础分不带庄闲&#xA;1.	接炮2分。&#xA;2.	自摸2分。&#xA;d)	3人基础分带庄闲&#xA;1.	庄家接炮：闲家-6分。&#xA;2.	庄家自摸：闲家-4分。&#xA;3.	闲家接炮：庄家-4分，闲家出分-2分。&#xA;4.	闲家自摸：庄家-4分，闲家出分-2分。&#xA;e)	3人基础分不带庄闲&#xA;1.	接炮2分。&#xA;2.	自摸2分。&#xA;f)	4人基础分带庄闲&#xA;1.	庄家接炮：闲家-8分。&#xA;2.	庄家自摸：闲家-4分。&#xA;3.	闲家接炮：庄家-6分，闲家出分-5分。&#xA;4.	闲家自摸：庄家-4分，闲家出分-2分。&#xA;g)	4人基础分不带庄闲&#xA;1.	接炮5分。&#xA;2.	自摸2分。&#xA;h)	胡牌出分人数&#xA;1.	接炮：点炮者1家出分。&#xA;2.	自摸：3家出分。&#xA;i)	胡牌牌型分：&#xA;1.	门清：胡牌时无碰、无明杠、无吃牌、且必须自摸胡牌     2分。&#xA;2.	抢杠胡：抢杠胡牌									 2分。&#xA;3.	杠上开花：杠后补牌胡牌							 2分。&#xA;4.	海底捞月：最后一张牌正好为要胡的牌					 2分。&#xA;5.	混一色：在清一色的基础上加上风牌胡牌				 2分。&#xA;6.	一条龙：胡牌时手中有同花色的123456789牌型			 2分。&#xA;7.	大吊车：4个刻子/杠加上一对将且为单吊胡牌			 2分。&#xA;8.	七对：7个对子胡牌									 2分。&#xA;9.	清一色：胡牌时所有牌为同一花色(万,筒,条)				3分。&#xA;10.	碰碰胡：4个刻子/杠加一对将胡牌						 3分。&#xA;11.	清风：胡牌时所有牌为风牌					         3分。&#xA;12.	花龙：胡牌时有3种花色的3副顺子连接成123456789的顺子 5分。&#xA;13.	捉五魁：单指46万胡5万的情形					     5分。&#xA;14.	十三幺：标准十三幺牌型胡牌					         10分。&#xA;15.	单豪七对：满足七对牌型，且有一副4张一样的牌		 8分。&#xA;16.	双豪七对：满足七对牌型，且有二副4张一样的牌		 16分。&#xA;17.	三豪七对：满足七对牌型，且有三副4张一样的牌		 32分。		&#xA;j)	杠分：&#xA;1.	明杠：1分，若未选择点杠包杠，则三人出分，若选择点杠包杠，则点杠者包三家杠分。&#xA;2.	面下杠：1分，三人出分。&#xA;3.	暗杠：2分，三人出分。&#xA;4.	荒庄荒杠分。&#xA;" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="TextObjectData">
                    <Size X="793.0000" Y="2500.0000" />
                    <AnchorPoint ScaleY="1.0000" />
                    <Position Y="1696.1100" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="132" G="31" B="19" />
                    <PrePosition Y="0.9977" />
                    <PreSize X="0.3848" Y="1.4706" />
                    <FontResource Type="Normal" Path="ui/font/FZY3JW.TTF" Plist="" />
                    <OutlineColor A="255" R="255" G="0" B="0" />
                    <ShadowColor A="255" R="110" G="110" B="110" />
                  </AbstractNodeData>
                </Children>
                <AnchorPoint />
                <Position X="-378.5135" Y="-253.9700" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <SingleColor A="255" R="255" G="150" B="100" />
                <FirstColor A="255" R="255" G="150" B="100" />
                <EndColor A="255" R="255" G="255" B="255" />
                <ColorVector ScaleY="1.0000" />
                <InnerNodeSize Width="2061" Height="1700" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="771.4700" Y="336.0240" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.6027" Y="0.4667" />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="pnLeft" ActionTag="-878780290" Tag="56" IconVisible="True" HorizontalEdge="LeftEdge" VerticalEdge="BothEdge" LeftMargin="221.5155" RightMargin="1058.4845" TopMargin="383.9760" BottomMargin="336.0240" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="lvGame" ActionTag="1427486485" Tag="332" IconVisible="False" LeftMargin="-133.0192" RightMargin="-136.9808" TopMargin="-265.8621" BottomMargin="-274.1379" TouchEnable="True" ClipAble="True" BackColorAlpha="102" ColorAngle="90.0000" Scale9Width="1" Scale9Height="1" IsBounceEnabled="True" ScrollDirectionType="0" ItemMargin="5" DirectionType="Vertical" ctype="ListViewObjectData">
                <Size X="270.0000" Y="540.0000" />
                <Children>
                  <AbstractNodeData Name="tdhmj" ActionTag="-1862363898" Tag="333" IconVisible="False" RightMargin="28.0000" BottomMargin="462.0000" TouchEnable="True" LeftEage="79" RightEage="79" TopEage="27" BottomEage="27" Scale9OriginX="79" Scale9OriginY="27" Scale9Width="84" Scale9Height="24" ctype="ImageViewObjectData">
                    <Size X="242.0000" Y="78.0000" />
                    <AnchorPoint ScaleY="0.5000" />
                    <Position Y="501.0000" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition Y="0.9278" />
                    <PreSize X="0.8963" Y="0.1444" />
                    <FileData Type="Normal" Path="ui/qj_createroom/qj_tdh_select.png" Plist="" />
                  </AbstractNodeData>
                </Children>
                <AnchorPoint />
                <Position X="-133.0192" Y="-274.1379" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <SingleColor A="255" R="150" G="150" B="255" />
                <FirstColor A="255" R="150" G="150" B="255" />
                <EndColor A="255" R="255" G="255" B="255" />
                <ColorVector ScaleY="1.0000" />
              </AbstractNodeData>
              <AbstractNodeData Name="stFengexian" CanEdit="False" ActionTag="-1499324784" Tag="58" IconVisible="False" LeftMargin="132.2137" RightMargin="-158.2137" TopMargin="-394.6972" BottomMargin="-325.3028" ctype="SpriteObjectData">
                <Size X="26.0000" Y="720.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="145.2137" Y="34.6972" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="ui/qj_commom/dt_fengexian.png" Plist="" />
                <BlendFunc Src="1" Dst="771" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="221.5155" Y="336.0240" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.1731" Y="0.4667" />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>