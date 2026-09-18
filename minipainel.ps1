# Painel de Automacao Desktop
# Interface Windows 11 Fluent WPF
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing

$scriptDir = if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } elseif ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$configFile = Join-Path $scriptDir "config.json"
$assetsDir = Join-Path $scriptDir "assets"

if (-not (Test-Path $configFile)) {
    $exampleFile = Join-Path $scriptDir "config.example.json"
    if (Test-Path $exampleFile) {
        Copy-Item $exampleFile $configFile
    } else {
        exit 1
    }
}

function Get-AppConfig {
    Get-Content -Path $configFile -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Save-AppConfig($cfg) {
    try {
        $json = $cfg | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($configFile, $json, [System.Text.Encoding]::UTF8)
    } catch {
        Write-Warning "Falha ao salvar configuracoes: $_"
    }
}

function Refresh-UI {
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

$config = Get-AppConfig

# Formatacao de data e saudacao
$culture = [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")
$rawDate = (Get-Date).ToString("dddd, dd 'de' MMMM", $culture)
$displayDate = (Get-Culture).TextInfo.ToTitleCase($rawDate)

$hour = (Get-Date).Hour
$periodGreeting = "Bom dia"
if ($hour -ge 12 -and $hour -lt 18) {
    $periodGreeting = "Boa tarde"
} elseif ($hour -ge 18 -or $hour -lt 5) {
    $periodGreeting = "Boa noite"
}

$userName = if ($config.user.name) { $config.user.name } else { "Marcos" }
$displayGreeting = "$periodGreeting, $userName"

if ($config.user.greetingType -eq "custom" -and $config.user.customGreeting) {
    $displayGreeting = $config.user.customGreeting
}

$accentColor = if ($config.user.accentColor) { $config.user.accentColor } else { "#0067C0" }
if (-not $config.user.accentColor) {
    if ($config.user -is [System.Management.Automation.PSCustomObject]) {
        $config.user | Add-Member -MemberType NoteProperty -Name "accentColor" -Value $accentColor -Force
    } else {
        $config.user.accentColor = $accentColor
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Inicializacao de Trabalho"
        Height="620" Width="450"
        WindowStartupLocation="CenterScreen"
        WindowStyle="None"
        AllowsTransparency="True"
        Background="Transparent"
        ResizeMode="NoResize"
        FontFamily="Segoe UI Variable Text, Segoe UI, sans-serif"
        TextElement.Foreground="#FFFFFF">

    <Window.Resources>
        <!-- Forcar cores escuras nativas em todos os Popups e Dropdowns do Windows -->
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowBrushKey}" Color="#252525"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowTextBrushKey}" Color="#FFFFFF"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="$accentColor"/>
        <SolidColorBrush x:Key="{x:Static SystemColors.HighlightTextBrushKey}" Color="#FFFFFF"/>

        <!-- Estilo dos Itens dos Dropdowns (ComboBoxItem) -->
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#252525"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Padding" Value="12,9"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border Name="ItemBorder" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}" CornerRadius="4" Margin="2,1">
                            <ContentPresenter ContentSource="Content" 
                                              TextBlock.Foreground="{TemplateBinding Foreground}"
                                              VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsHighlighted" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="#383838"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="ItemBorder" Property="Background" Value="$accentColor"/>
                                <Setter Property="Foreground" Value="#FFFFFF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Estilo do proprio ComboBox com Template Escuro Nativo Windows 11 -->
        <Style TargetType="ComboBox">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="MaxDropDownHeight" Value="240"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <ToggleButton Name="ToggleButton" 
                                          Focusable="False" 
                                          IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" 
                                          ClickMode="Press">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border Name="Border" Background="#2B2B2B" BorderBrush="#3D3D3D" BorderThickness="1" CornerRadius="6" Padding="10,6">
                                            <Grid>
                                                <Grid.ColumnDefinitions>
                                                    <ColumnDefinition Width="*"/>
                                                    <ColumnDefinition Width="24"/>
                                                </Grid.ColumnDefinitions>
                                                <Path Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" Fill="#A0A0A0" Data="M 0 0 L 4 4 L 8 0 Z"/>
                                            </Grid>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter TargetName="Border" Property="Background" Value="#333333"/>
                                                <Setter TargetName="Border" Property="BorderBrush" Value="#555555"/>
                                            </Trigger>
                                            <Trigger Property="IsChecked" Value="True">
                                                <Setter TargetName="Border" Property="BorderBrush" Value="$accentColor"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            
                            <ContentPresenter Name="ContentSite" 
                                              IsHitTestVisible="False" 
                                              Content="{TemplateBinding SelectionBoxItem}" 
                                              ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" 
                                              ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" 
                                              VerticalAlignment="Center" 
                                              HorizontalAlignment="Left" 
                                              Margin="12,0,30,0">
                                <ContentPresenter.Resources>
                                    <Style TargetType="TextBlock">
                                        <Setter Property="Foreground" Value="#FFFFFF"/>
                                    </Style>
                                </ContentPresenter.Resources>
                            </ContentPresenter>

                            <Popup Name="Popup" 
                                   Placement="Bottom" 
                                   IsOpen="{TemplateBinding IsDropDownOpen}" 
                                   AllowsTransparency="True" 
                                   Focusable="False" 
                                   PopupAnimation="Slide">
                                <Grid Name="DropDown" 
                                      SnapsToDevicePixels="True" 
                                      MinWidth="{TemplateBinding ActualWidth}" 
                                      MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                    <Border Name="DropDownBorder" 
                                            Background="#252525" 
                                            BorderBrush="#3D3D3D" 
                                            BorderThickness="1" 
                                            CornerRadius="6" 
                                            Margin="0,4,0,4">
                                        <Border.Effect>
                                            <DropShadowEffect BlurRadius="14" ShadowDepth="4" Opacity="0.5" Color="#000000"/>
                                        </Border.Effect>
                                        <ScrollViewer Margin="2" SnapsToDevicePixels="True">
                                            <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                        </ScrollViewer>
                                    </Border>
                                </Grid>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Estilo dos TextBox -->
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#2B2B2B"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#3D3D3D"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="CaretBrush" Value="#FFFFFF"/>
        </Style>
    </Window.Resources>

    <Border CornerRadius="12" Background="#202020" BorderBrush="#333333" BorderThickness="1">
        <Border.Effect>
            <DropShadowEffect BlurRadius="28" ShadowDepth="8" Opacity="0.45" Color="#000000"/>
        </Border.Effect>

        <Grid Margin="20,18,20,18">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- BARRA SUPERIOR -->
            <Grid Grid.Row="0" Margin="0,0,0,16" Name="TopBarGrid">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>

                <StackPanel VerticalAlignment="Center">
                    <TextBlock Name="TxtGreeting" Text="$displayGreeting" FontSize="17" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                    <TextBlock Name="TxtDate" Text="$displayDate" FontSize="12" Foreground="#A0A0A0" Margin="0,2,0,0"/>
                </StackPanel>

                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Button Name="BtnNavAdd" Content="+ Item" Height="28" Padding="10,0" Margin="0,0,6,0"
                            Background="#2B2B2B" Foreground="#FFFFFF" BorderBrush="#3D3D3D" BorderThickness="1" 
                            Cursor="Hand" FontSize="12">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                    <Button Name="BtnNavSettings" Content="Opcoes" Height="28" Padding="10,0" Margin="0,0,8,0"
                            Background="#2B2B2B" Foreground="#FFFFFF" BorderBrush="#3D3D3D" BorderThickness="1" 
                            Cursor="Hand" FontSize="12">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                    <Button Name="BtnCloseWindow" Content="✕" Width="28" Height="28"
                            Background="#2B2B2B" Foreground="#A0A0A0" BorderBrush="#3D3D3D" BorderThickness="1" 
                            Cursor="Hand" FontSize="11" FontWeight="SemiBold">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                </StackPanel>
            </Grid>

            <!-- VIEW 1: PRINCIPAL -->
            <Grid Grid.Row="1" Name="ViewMain" Visibility="Visible">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <Grid Grid.Row="0" Margin="0,0,0,10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="Selecione o que deseja abrir hoje:" FontSize="12" Foreground="#A0A0A0" VerticalAlignment="Center"/>
                    <StackPanel Grid.Column="1" Orientation="Horizontal">
                        <Button Name="BtnSelectAll" Content="Marcar todos" Background="Transparent" Foreground="#60CDFF" BorderThickness="0" Cursor="Hand" FontSize="11" Margin="0,0,8,0"/>
                        <TextBlock Text="•" Foreground="#555555" VerticalAlignment="Center" Margin="0,0,8,0"/>
                        <Button Name="BtnDeselectAll" Content="Desmarcar" Background="Transparent" Foreground="#A0A0A0" BorderThickness="0" Cursor="Hand" FontSize="11"/>
                    </StackPanel>
                </Grid>

                <Border Grid.Row="1" Background="#181818" CornerRadius="8" BorderBrush="#2C2C2C" BorderThickness="1" Padding="4,6">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel Name="ItemsContainer"/>
                    </ScrollViewer>
                </Border>

                <TextBlock Grid.Row="2" Name="TxtStatus" Text="Itens prontos para iniciar" 
                           FontSize="12" Foreground="#A0A0A0" TextAlignment="Center" Margin="0,10,0,8"/>

                <Button Grid.Row="3" Name="BtnLaunch" Height="44" Cursor="Hand"
                        Background="$accentColor" Foreground="#FFFFFF" BorderThickness="0"
                        FontSize="13.5" FontWeight="SemiBold">
                    <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    <TextBlock Name="TxtLaunchBtn" Text="Iniciar rotina de trabalho" Foreground="#FFFFFF" VerticalAlignment="Center"/>
                </Button>
            </Grid>

            <!-- VIEW 2: ADICIONAR ITEM -->
            <Grid Grid.Row="1" Name="ViewAdd" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="Adicionar novo item a rotina" FontSize="15" FontWeight="SemiBold" Foreground="#FFFFFF" Margin="0,0,0,16"/>

                <StackPanel Grid.Row="1">
                    <TextBlock Text="Nome ou apelido" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4"/>
                    <TextBox Name="InputItemName" Height="36" Margin="0,0,0,14">
                        <TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></TextBox.Resources>
                    </TextBox>

                    <TextBlock Text="Tipo de recurso" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4"/>
                    <ComboBox Name="ComboItemType" Height="36" Margin="0,0,0,14">
                        <ComboBoxItem Content="Planilha Google Sheets" IsSelected="True"/>
                        <ComboBoxItem Content="Site ou Link da Web"/>
                        <ComboBoxItem Content="Programa (.exe)"/>
                        <ComboBoxItem Content="Pasta de Arquivos"/>
                    </ComboBox>

                    <TextBlock Name="LblTarget" Text="Link completo (URL da planilha)" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4"/>
                    <TextBox Name="InputItemTarget" Height="36" Margin="0,0,0,14">
                        <TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></TextBox.Resources>
                    </TextBox>
                </StackPanel>

                <Grid Grid.Row="2" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button Grid.Column="0" Name="BtnCancelAdd" Content="Cancelar" Height="38" Margin="0,0,6,0"
                            Background="#2B2B2B" Foreground="#FFFFFF" BorderBrush="#3D3D3D" BorderThickness="1" 
                            Cursor="Hand" FontSize="12.5">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                    <Button Grid.Column="1" Name="BtnSaveAdd" Content="Salvar item" Height="38" Margin="6,0,0,0"
                            Background="$accentColor" Foreground="#FFFFFF" BorderThickness="0" 
                            Cursor="Hand" FontSize="12.5" FontWeight="SemiBold">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                </Grid>
            </Grid>

            <!-- VIEW 3: OPCOES / CONFIGURACOES -->
            <Grid Grid.Row="1" Name="ViewSettings" Visibility="Collapsed">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="Configuracoes do aplicativo" FontSize="15" FontWeight="SemiBold" Foreground="#FFFFFF" Margin="0,0,0,16"/>

                <StackPanel Grid.Row="1">
                    <TextBlock Text="Seu nome" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4"/>
                    <TextBox Name="InputUserName" Height="36" Margin="0,0,0,14">
                        <TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></TextBox.Resources>
                    </TextBox>

                    <TextBlock Text="Cor de destaque" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4"/>
                    <ComboBox Name="ComboThemeColor" Height="36" Margin="0,0,0,14">
                        <ComboBoxItem Content="Azul Windows"/>
                        <ComboBoxItem Content="Verde Office / Excel"/>
                        <ComboBoxItem Content="Roxo Moderno"/>
                        <ComboBoxItem Content="Cinza Grafite"/>
                    </ComboBox>

                    <TextBlock Text="Estilo da saudacao" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4"/>
                    <ComboBox Name="ComboGreetingType" Height="36" Margin="0,0,0,14">
                        <ComboBoxItem Content="Automatico por horario (Bom dia / Boa tarde)"/>
                        <ComboBoxItem Content="Frase personalizada"/>
                    </ComboBox>

                    <TextBlock Name="LblCustomGreeting" Text="Frase personalizada" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4" Visibility="Collapsed"/>
                    <TextBox Name="InputCustomGreeting" Height="36" Margin="0,0,0,14" Visibility="Collapsed">
                        <TextBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></TextBox.Resources>
                    </TextBox>

                    <CheckBox Name="CheckCloseAfter" Content="Fechar janela automaticamente apos abrir itens" 
                              Foreground="#FFFFFF" FontSize="12.5" Margin="0,4,0,8" Cursor="Hand"/>
                </StackPanel>

                <Grid Grid.Row="2" Margin="0,10,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Button Grid.Column="0" Name="BtnCancelSettings" Content="Cancelar" Height="38" Margin="0,0,6,0"
                            Background="#2B2B2B" Foreground="#FFFFFF" BorderBrush="#3D3D3D" BorderThickness="1" 
                            Cursor="Hand" FontSize="12.5">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                    <Button Grid.Column="1" Name="BtnSaveSettings" Content="Salvar alteracoes" Height="38" Margin="6,0,0,0"
                            Background="$accentColor" Foreground="#FFFFFF" BorderThickness="0" 
                            Cursor="Hand" FontSize="12.5" FontWeight="SemiBold">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                    </Button>
                </Grid>
            </Grid>

        </Grid>
    </Border>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Mapeamento de controles
$topBarGrid = $window.FindName("TopBarGrid")
$btnCloseWindow = $window.FindName("BtnCloseWindow")
$btnNavAdd = $window.FindName("BtnNavAdd")
$btnNavSettings = $window.FindName("BtnNavSettings")
$txtGreeting = $window.FindName("TxtGreeting")

$viewMain = $window.FindName("ViewMain")
$viewAdd = $window.FindName("ViewAdd")
$viewSettings = $window.FindName("ViewSettings")

$itemsContainer = $window.FindName("ItemsContainer")
$btnSelectAll = $window.FindName("BtnSelectAll")
$btnDeselectAll = $window.FindName("BtnDeselectAll")
$txtStatus = $window.FindName("TxtStatus")
$btnLaunch = $window.FindName("BtnLaunch")
$txtLaunchBtn = $window.FindName("TxtLaunchBtn")

# Form Adicionar
$inputItemName = $window.FindName("InputItemName")
$comboItemType = $window.FindName("ComboItemType")
$lblTarget = $window.FindName("LblTarget")
$inputItemTarget = $window.FindName("InputItemTarget")
$btnCancelAdd = $window.FindName("BtnCancelAdd")
$btnSaveAdd = $window.FindName("BtnSaveAdd")

# Form Opcoes
$inputUserName = $window.FindName("InputUserName")
$comboThemeColor = $window.FindName("ComboThemeColor")
$comboGreetingType = $window.FindName("ComboGreetingType")
$lblCustomGreeting = $window.FindName("LblCustomGreeting")
$inputCustomGreeting = $window.FindName("InputCustomGreeting")
$checkCloseAfter = $window.FindName("CheckCloseAfter")
$btnCancelSettings = $window.FindName("BtnCancelSettings")
$btnSaveSettings = $window.FindName("BtnSaveSettings")

# Arrastar janela
$topBarGrid.Add_MouseDown({
    if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
        $window.DragMove()
    }
})

# Fechar janela
$btnCloseWindow.Add_Click({ $window.Close() })

function Show-View($name) {
    $viewMain.Visibility = if ($name -eq "main") { "Visible" } else { "Collapsed" }
    $viewAdd.Visibility = if ($name -eq "add") { "Visible" } else { "Collapsed" }
    $viewSettings.Visibility = if ($name -eq "settings") { "Visible" } else { "Collapsed" }
}

$btnNavAdd.Add_Click({
    $inputItemName.Text = ""
    $inputItemTarget.Text = ""
    $comboItemType.SelectedIndex = 0
    Show-View "add"
})

$btnCancelAdd.Add_Click({ Show-View "main" })

$btnNavSettings.Add_Click({
    $inputUserName.Text = if ($config.user.name) { $config.user.name } else { "Marcos" }
    
    $colorIndex = 0
    if ($config.user.accentColor -eq "#107C41") { $colorIndex = 1 }
    elseif ($config.user.accentColor -eq "#673AB7") { $colorIndex = 2 }
    elseif ($config.user.accentColor -eq "#4B5563") { $colorIndex = 3 }
    $comboThemeColor.SelectedIndex = $colorIndex

    $comboGreetingType.SelectedIndex = if ($config.user.greetingType -eq "custom") { 1 } else { 0 }
    $inputCustomGreeting.Text = $config.user.customGreeting
    $checkCloseAfter.IsChecked = if ($null -ne $config.user.closeAfterLaunch) { [bool]$config.user.closeAfterLaunch } else { $true }

    $isCustom = ($comboGreetingType.SelectedIndex -eq 1)
    $lblCustomGreeting.Visibility = if ($isCustom) { "Visible" } else { "Collapsed" }
    $inputCustomGreeting.Visibility = if ($isCustom) { "Visible" } else { "Collapsed" }
    Show-View "settings"
})

$comboGreetingType.Add_SelectionChanged({
    $isCustom = ($comboGreetingType.SelectedIndex -eq 1)
    $lblCustomGreeting.Visibility = if ($isCustom) { "Visible" } else { "Collapsed" }
    $inputCustomGreeting.Visibility = if ($isCustom) { "Visible" } else { "Collapsed" }
})

$btnCancelSettings.Add_Click({ Show-View "main" })

$btnSaveSettings.Add_Click({
    $config.user.name = $inputUserName.Text.Trim()
    
    $chosenColor = "#0067C0"
    switch ($comboThemeColor.SelectedIndex) {
        0 { $chosenColor = "#0067C0" }
        1 { $chosenColor = "#107C41" }
        2 { $chosenColor = "#673AB7" }
        3 { $chosenColor = "#4B5563" }
    }
    $config.user.accentColor = $chosenColor
    $config.user.greetingType = if ($comboGreetingType.SelectedIndex -eq 1) { "custom" } else { "auto" }
    $config.user.customGreeting = $inputCustomGreeting.Text.Trim()
    $config.user.closeAfterLaunch = [bool]$checkCloseAfter.IsChecked
    Save-AppConfig $config

    $currentGreeting = "$periodGreeting, $($config.user.name)"
    if ($config.user.greetingType -eq "custom" -and $config.user.customGreeting) {
        $currentGreeting = $config.user.customGreeting
    }
    $txtGreeting.Text = $currentGreeting
    
    $brush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($chosenColor)
    $btnLaunch.Background = $brush
    $btnSaveAdd.Background = $brush
    $btnSaveSettings.Background = $brush

    Render-Items
    Show-View "main"
})

$comboItemType.Add_SelectionChanged({
    switch ($comboItemType.SelectedIndex) {
        0 { $lblTarget.Text = "Link da planilha (URL do Google Sheets)" }
        1 { $lblTarget.Text = "Link do site (URL)" }
        2 { $lblTarget.Text = "Caminho do programa (.exe)" }
        3 { $lblTarget.Text = "Caminho da pasta" }
    }
})

$btnSaveAdd.Add_Click({
    $name = $inputItemName.Text.Trim()
    $target = $inputItemTarget.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($target)) {
        return
    }

    $type = "url"
    $cat = "Planilha"
    switch ($comboItemType.SelectedIndex) {
        0 { $type = "url"; $cat = "Planilha" }
        1 { $type = "url"; $cat = "Web" }
        2 { $type = "app"; $cat = "App" }
        3 { $type = "folder"; $cat = "Pasta" }
    }

    $newItem = @{
        id = "item_" + (Get-Date).Ticks
        name = $name
        category = $cat
        type = $type
        target = $target
        processName = ""
        args = ""
        enabled = $true
    }

    $config.items = @($config.items) + [PSCustomObject]$newItem
    Save-AppConfig $config

    Render-Items
    Show-View "main"
})

function Get-RealIconPath($item) {
    $nameLower = ($item.name + " " + $item.category).ToLower()
    $targetLower = ($item.target).ToLower()

    if ($nameLower -match "fiel|transatila|planilha|sheet" -or $targetLower -match "spreadsheets|docs.google") {
        return (Join-Path $assetsDir "sheets.png")
    }
    if ($nameLower -match "outlook|e-mail|email" -or $targetLower -match "outlook") {
        return (Join-Path $assetsDir "outlook.png")
    }
    if ($nameLower -match "teams|reuniao" -or $targetLower -match "teams") {
        return (Join-Path $assetsDir "teams.png")
    }
    if ($nameLower -match "whatsapp|whats|zap" -or $targetLower -match "whatsapp") {
        return (Join-Path $assetsDir "whatsapp.png")
    }
    return (Join-Path $assetsDir "chrome.png")
}

function Get-ItemSubtitle($item) {
    $nameLower = ($item.name + " " + $item.category).ToLower()
    $targetLower = ($item.target).ToLower()

    if ($nameLower -match "fiel|transatila|planilha|sheet" -or $targetLower -match "spreadsheets") {
        return "Google Sheets • Google Chrome"
    }
    if ($nameLower -match "outlook") {
        return "Microsoft Outlook • Área de Trabalho"
    }
    if ($nameLower -match "teams") {
        return "Microsoft Teams • Comunicação"
    }
    if ($nameLower -match "whatsapp") {
        return "WhatsApp Desktop • Mensagens"
    }
    if ($item.type -eq "app") {
        return "Aplicativo Windows"
    }
    return "Navegador Web"
}

# Dicionario de controladores de itens
$itemControllers = @{}

function Update-ButtonCount {
    $activeCount = 0
    $totalCount = $config.items.Count
    foreach ($k in $itemControllers.Keys) {
        if ($itemControllers[$k].IsChecked) { $activeCount++ }
    }

    if ($activeCount -eq 0) {
        $txtLaunchBtn.Text = "Selecione ao menos um item"
        $btnLaunch.IsEnabled = $false
        $btnLaunch.Opacity = 0.45
        $txtStatus.Text = "Nenhum item marcado para abrir"
        $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E06A3B")
    } else {
        $txtLaunchBtn.Text = "Iniciar rotina de trabalho ($activeCount)"
        $btnLaunch.IsEnabled = $true
        $btnLaunch.Opacity = 1.0
        $txtStatus.Text = "$activeCount de $totalCount itens selecionados para abrir"
        $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A0A0A0")
    }
    Refresh-UI
}

function Render-Items {
    $itemsContainer.Children.Clear()
    $itemControllers.Clear()

    $accentHex = if ($config.user.accentColor) { $config.user.accentColor } else { "#0067C0" }
    $brushAccent = [System.Windows.Media.BrushConverter]::new().ConvertFromString($accentHex)
    $brushActiveBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A2A2A")
    $brushInactiveBg = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1C1C1C")
    $brushInactiveBorder = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E2E2E")
    $brushWhite = [System.Windows.Media.Brushes]::White
    $brushActiveSub = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A8A8A8")
    $brushInactiveTitle = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#888888")
    $brushInactiveSub = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#5E5E5E")
    $brushSwitchOff = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3A3A3A")
    $brushLabelOff = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#777777")

    foreach ($item in $config.items) {
        $iconPath = Get-RealIconPath $item
        $subtitle = Get-ItemSubtitle $item
        $itemId = $item.id
        $initialState = if ($null -ne $item.enabled) { [bool]$item.enabled } else { $true }

        # Card Principal
        $card = New-Object System.Windows.Controls.Border
        $card.CornerRadius = (New-Object System.Windows.CornerRadius(8))
        $card.BorderThickness = (New-Object System.Windows.Thickness(1.5))
        $card.Margin = (New-Object System.Windows.Thickness(0, 3, 0, 5))
        $card.Padding = (New-Object System.Windows.Thickness(12, 10, 12, 10))
        $card.Cursor = [System.Windows.Input.Cursors]::Hand

        $grid = New-Object System.Windows.Controls.Grid
        $colIcon = New-Object System.Windows.Controls.ColumnDefinition
        $colIcon.Width = [System.Windows.GridLength]::Auto
        $colText = New-Object System.Windows.Controls.ColumnDefinition
        $colText.Width = (New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star))
        $colSwitch = New-Object System.Windows.Controls.ColumnDefinition
        $colSwitch.Width = [System.Windows.GridLength]::Auto
        $colDel = New-Object System.Windows.Controls.ColumnDefinition
        $colDel.Width = [System.Windows.GridLength]::Auto

        $grid.ColumnDefinitions.Add($colIcon)
        $grid.ColumnDefinitions.Add($colText)
        $grid.ColumnDefinitions.Add($colSwitch)
        $grid.ColumnDefinitions.Add($colDel)

        # Icone
        $img = New-Object System.Windows.Controls.Image
        $img.Width = 32
        $img.Height = 32
        $img.Margin = (New-Object System.Windows.Thickness(0, 0, 14, 0))
        $img.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, [System.Windows.Media.BitmapScalingMode]::HighQuality)
        if (Test-Path $iconPath) {
            $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
            $bitmap.BeginInit()
            $bitmap.UriSource = New-Object System.Uri $iconPath
            $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bitmap.EndInit()
            $img.Source = $bitmap
        }
        [System.Windows.Controls.Grid]::SetColumn($img, 0)
        $grid.Children.Add($img) | Out-Null

        # Rotulo e categoria
        $textSp = New-Object System.Windows.Controls.StackPanel
        $textSp.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

        $titleTb = New-Object System.Windows.Controls.TextBlock
        $titleTb.Text = $item.name
        $titleTb.FontSize = 13.5
        $titleTb.FontWeight = [System.Windows.FontWeights]::SemiBold
        $titleTb.Foreground = [System.Windows.Media.Brushes]::White

        $subTb = New-Object System.Windows.Controls.TextBlock
        $subTb.Text = $subtitle
        $subTb.FontSize = 11.5
        $subTb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A8A8A8")
        $subTb.Margin = (New-Object System.Windows.Thickness(0, 2, 0, 0))

        $textSp.Children.Add($titleTb) | Out-Null
        $textSp.Children.Add($subTb) | Out-Null
        [System.Windows.Controls.Grid]::SetColumn($textSp, 1)
        $grid.Children.Add($textSp) | Out-Null

        # Switch de alternancia
        $switchContainer = New-Object System.Windows.Controls.StackPanel
        $switchContainer.Orientation = [System.Windows.Controls.Orientation]::Horizontal
        $switchContainer.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $switchContainer.Margin = (New-Object System.Windows.Thickness(8, 0, 8, 0))

        $stateLabel = New-Object System.Windows.Controls.TextBlock
        $stateLabel.FontSize = 11.5
        $stateLabel.FontWeight = [System.Windows.FontWeights]::SemiBold
        $stateLabel.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $stateLabel.Margin = (New-Object System.Windows.Thickness(0, 0, 8, 0))

        $switchBorder = New-Object System.Windows.Controls.Border
        $switchBorder.Width = 40
        $switchBorder.Height = 22
        $switchBorder.CornerRadius = (New-Object System.Windows.CornerRadius(11))
        $switchBorder.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

        $thumb = New-Object System.Windows.Controls.Border
        $thumb.Width = 16
        $thumb.Height = 16
        $thumb.CornerRadius = (New-Object System.Windows.CornerRadius(8))
        $thumb.Background = [System.Windows.Media.Brushes]::White
        $thumb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $switchBorder.Child = $thumb

        $switchContainer.Children.Add($stateLabel) | Out-Null
        $switchContainer.Children.Add($switchBorder) | Out-Null

        [System.Windows.Controls.Grid]::SetColumn($switchContainer, 2)
        $grid.Children.Add($switchContainer) | Out-Null

        # Botao remover
        $btnDel = New-Object System.Windows.Controls.Button
        $btnDel.Content = "✕"
        $btnDel.Width = 24
        $btnDel.Height = 24
        $btnDel.Background = [System.Windows.Media.Brushes]::Transparent
        $btnDel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#666666")
        $btnDel.BorderThickness = (New-Object System.Windows.Thickness(0))
        $btnDel.Cursor = [System.Windows.Input.Cursors]::Hand
        $btnDel.FontSize = 11
        $btnDel.ToolTip = "Remover da rotina"

        $deleteId = $item.id
        $delHandler = {
            $config.items = @($config.items | Where-Object { $_.id -ne $deleteId })
            Save-AppConfig $config
            Render-Items
        }.GetNewClosure()
        $btnDel.Add_Click($delHandler)

        [System.Windows.Controls.Grid]::SetColumn($btnDel, 3)
        $grid.Children.Add($btnDel) | Out-Null

        $card.Child = $grid
        $itemsContainer.Children.Add($card) | Out-Null

        # Estado do item
        $targetCard = $card
        $targetSwitch = $switchBorder
        $targetThumb = $thumb
        $targetStateLabel = $stateLabel
        $targetTitle = $titleTb
        $targetSub = $subTb
        $targetItem = $item
        $targetBtnDel = $btnDel

        $controller = [PSCustomObject]@{
            Id = $itemId
            IsChecked = $initialState
        }

        $applyStateVisual = {
            param([bool]$active)
            $controller.IsChecked = $active
            $targetItem.enabled = $active

            if ($active) {
                $targetCard.Opacity = 1.0
                $targetCard.Background = $brushActiveBg
                $targetCard.BorderBrush = $brushAccent
                
                $targetTitle.Foreground = $brushWhite
                $targetSub.Foreground = $brushActiveSub

                $targetSwitch.Background = $brushAccent
                $targetThumb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
                $targetThumb.Margin = (New-Object System.Windows.Thickness(0, 0, 3, 0))

                $targetStateLabel.Text = "Abrir"
                $targetStateLabel.Foreground = $brushWhite
            } else {
                $targetCard.Opacity = 0.55
                $targetCard.Background = $brushInactiveBg
                $targetCard.BorderBrush = $brushInactiveBorder
                
                $targetTitle.Foreground = $brushInactiveTitle
                $targetSub.Foreground = $brushInactiveSub

                $targetSwitch.Background = $brushSwitchOff
                $targetThumb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Left
                $targetThumb.Margin = (New-Object System.Windows.Thickness(3, 0, 0, 0))

                $targetStateLabel.Text = "Pular"
                $targetStateLabel.Foreground = $brushLabelOff
            }
        }.GetNewClosure()

        $controller | Add-Member -MemberType ScriptMethod -Name "SetState" -Value $applyStateVisual
        $controller.SetState($initialState)

        # Alternar estado ao clicar
        $cardClickHandler = {
            param($sender, $e)
            if ($e.OriginalSource -eq $targetBtnDel -or ($e.OriginalSource -is [System.Windows.Controls.TextBlock] -and $e.OriginalSource.Text -eq "✕")) {
                return
            }
            try {
                $newState = -not $controller.IsChecked
                $controller.SetState($newState)
                Save-AppConfig $config
                Update-ButtonCount
            } catch {
                Write-Warning "Erro ao alternar item: $_"
            }
        }.GetNewClosure()

        $targetCard.Add_MouseLeftButtonDown($cardClickHandler)
        $itemControllers[$itemId] = $controller
    }

    Update-ButtonCount
}

# Botoes Marcar Todos / Desmarcar
$btnSelectAll.Add_Click({
    foreach ($k in $itemControllers.Keys) {
        $itemControllers[$k].SetState($true)
    }
    Save-AppConfig $config
    Update-ButtonCount
})

$btnDeselectAll.Add_Click({
    foreach ($k in $itemControllers.Keys) {
        $itemControllers[$k].SetState($false)
    }
    Save-AppConfig $config
    Update-ButtonCount
})

# Acao Iniciar
$btnLaunch.Add_Click({
    $btnLaunch.IsEnabled = $false
    $btnLaunch.Opacity = 0.6
    $txtStatus.Text = "Iniciando itens selecionados..."

    Refresh-UI

    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    $preventDupes = if ($null -ne $config.settings.preventDuplicates) { [bool]$config.settings.preventDuplicates } else { $true }

    $selectedItems = @()
    foreach ($item in $config.items) {
        if ($itemControllers.ContainsKey($item.id) -and $itemControllers[$item.id].IsChecked) {
            $selectedItems += $item
        }
    }

    $count = 0
    foreach ($it in $selectedItems) {
        $count++
        $txtStatus.Text = "Abrindo: $($it.name)... ($count/$($selectedItems.Count))"
        Refresh-UI

        try {
            switch ($it.type.ToLower()) {
                "app" {
                    if ($preventDupes -and $it.processName) {
                        $running = Get-Process -Name $it.processName -ErrorAction SilentlyContinue
                        if ($running) {
                            continue
                        }
                    }

                    if ($it.target -eq "whatsapp:" -or $it.id -eq "whatsapp") {
                        $waPkg = Get-AppxPackage *WhatsApp* -ErrorAction SilentlyContinue
                        if ($waPkg) {
                            Start-Process "explorer.exe" -ArgumentList "shell:AppsFolder\$($waPkg.PackageFamilyName)!App"
                        } else {
                            Start-Process "whatsapp:"
                        }
                    } elseif (Test-Path $it.target) {
                        if ($it.args) {
                            Start-Process -FilePath $it.target -ArgumentList $it.args
                        } else {
                            Start-Process -FilePath $it.target
                        }
                    } else {
                        Start-Process -FilePath $it.target
                    }
                }
                "url" {
                    if (Test-Path $chromePath) {
                        Start-Process -FilePath $chromePath -ArgumentList "`"$($it.target)`""
                    } else {
                        Start-Process $it.target
                    }
                }
                "folder" {
                    if (Test-Path $it.target) {
                        Start-Process "explorer.exe" -ArgumentList "`"$($it.target)`""
                    }
                }
            }
        } catch {
            Write-Host "Falha ao abrir $($it.name): $_"
        }

        Start-Sleep -Milliseconds 400
    }

    $txtStatus.Text = "Aplicativos e planilhas abertos com sucesso."
    $txtStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#60CDFF")
    Refresh-UI

    $closeAfter = if ($null -ne $config.user.closeAfterLaunch) { [bool]$config.user.closeAfterLaunch } else { $true }
    if ($closeAfter) {
        Start-Sleep -Milliseconds 1200
        $window.Close()
    } else {
        $btnLaunch.IsEnabled = $true
        $btnLaunch.Opacity = 1.0
    }
})

# Inicializacao
Render-Items
$window.ShowDialog() | Out-Null
