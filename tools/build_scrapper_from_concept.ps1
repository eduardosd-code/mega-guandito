param(
    [string]$SourceDirectory = "$PSScriptRoot\..\assets\concept\SCRAPPER",
    [string]$OutputDirectory = "$PSScriptRoot\..\assets\enemies\sector_07\scrapper\sprites"
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$drawingAssembly = [System.Drawing.Bitmap].Assembly.Location
$runtimeDirectory = Split-Path $drawingAssembly
$references = @(
    $drawingAssembly,
    (Join-Path $runtimeDirectory 'System.Drawing.Primitives.dll'),
    (Join-Path $runtimeDirectory 'System.Private.Windows.GdiPlus.dll'),
    (Join-Path $runtimeDirectory 'System.Private.Windows.Core.dll'),
    (Join-Path $runtimeDirectory 'System.Private.CoreLib.dll'),
    (Join-Path $runtimeDirectory 'System.Runtime.dll'),
    (Join-Path $runtimeDirectory 'System.Collections.dll')
)

Add-Type -ReferencedAssemblies $references -TypeDefinition @'
using System;
using System.Collections;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class ScrapperConceptBuilder {
    class Component {
        public int Id, Pixels, MinX, MinY, MaxX, MaxY;
        public double CenterX { get { return (MinX+MaxX)/2.0; } }
    }
    struct FrameInfo {
        public int X0, X1, MinX, MinY, MaxX, MaxY, FootY;
        public double BodyCenterX;
    }

    static bool Visible(Color color) { return color.A >= 96; }

    static Component[] FindCharacters(Bitmap source, int expected, out int[] labels) {
        int w=source.Width,h=source.Height; labels=new int[w*h]; int[] queue=new int[w*h]; var components=new ArrayList(); int id=0;
        int[] dx={-1,0,1,-1,1,-1,0,1},dy={-1,-1,-1,0,0,1,1,1};
        for(int sy=0;sy<h;sy++) for(int sx=0;sx<w;sx++) {
            int start=sy*w+sx; if(labels[start]!=0 || !Visible(source.GetPixel(sx,sy))) continue;
            id++; int head=0,tail=0; queue[tail++]=start; labels[start]=id;
            var c=new Component{Id=id,MinX=sx,MaxX=sx,MinY=sy,MaxY=sy};
            while(head<tail){int p=queue[head++],x=p%w,y=p/w;c.Pixels++;c.MinX=Math.Min(c.MinX,x);c.MaxX=Math.Max(c.MaxX,x);c.MinY=Math.Min(c.MinY,y);c.MaxY=Math.Max(c.MaxY,y);
                for(int d=0;d<8;d++){int nx=x+dx[d],ny=y+dy[d];if(nx<0||ny<0||nx>=w||ny>=h)continue;int np=ny*w+nx;if(labels[np]==0&&Visible(source.GetPixel(nx,ny))){labels[np]=id;queue[tail++]=np;}}
            }
            if(c.Pixels>250) components.Add(c);
        }
        var selected=new Component[expected]; var used=new bool[components.Count];
        for(int k=0;k<expected;k++){int best=-1;for(int i=0;i<components.Count;i++)if(!used[i]&&(best<0||((Component)components[i]).Pixels>((Component)components[best]).Pixels))best=i;if(best<0)throw new InvalidDataException("Not enough isolated characters");used[best]=true;selected[k]=(Component)components[best];}
        for(int i=0;i<selected.Length-1;i++)for(int j=i+1;j<selected.Length;j++)if(selected[j].CenterX<selected[i].CenterX){var t=selected[i];selected[i]=selected[j];selected[j]=t;}
        return selected;
    }

    static FrameInfo Analyze(Bitmap source, int frame, int count) {
        int x0 = (int)Math.Floor((double)frame * source.Width / count);
        int x1 = (int)Math.Floor((double)(frame + 1) * source.Width / count) - 1;
        var info = new FrameInfo { X0=x0, X1=x1, MinX=x1, MinY=source.Height-1, MaxX=x0, MaxY=0 };
        int slotWidth = x1-x0+1;
        var columns = new int[slotWidth];
        for (int y=0;y<source.Height;y++) for (int x=x0;x<=x1;x++) if (Visible(source.GetPixel(x,y))) {
            columns[x-x0]++; info.MinX=Math.Min(info.MinX,x); info.MaxX=Math.Max(info.MaxX,x); info.MinY=Math.Min(info.MinY,y); info.MaxY=Math.Max(info.MaxY,y);
        }
        if (info.MaxX < info.MinX) throw new InvalidDataException("Empty frame " + frame);

        // Find the densest vertical window, which follows the torso instead of
        // the extended wrench, cable, or detached death pieces.
        int window = Math.Min(slotWidth, Math.Max(32, source.Height/4));
        int sum=0; for(int x=0;x<window;x++) sum+=columns[x];
        int best=sum, bestStart=0;
        for(int x=window;x<slotWidth;x++){ sum+=columns[x]-columns[x-window]; if(sum>best){best=sum;bestStart=x-window+1;} }
        int bx0=x0+bestStart, bx1=bx0+window-1, pixels=0; long weightedX=0; int foot=0;
        for(int y=0;y<source.Height;y++) for(int x=bx0;x<=bx1;x++) if(Visible(source.GetPixel(x,y))){weightedX+=x;pixels++;foot=Math.Max(foot,y);}
        info.BodyCenterX = pixels > 0 ? (double)weightedX/pixels : (info.MinX+info.MaxX)/2.0;
        info.FootY = foot > 0 ? foot : info.MaxY;
        return info;
    }

    static double AnimationScale(string sourcePath, int count, bool death) {
        using(var idle=new Bitmap(sourcePath)) {
            var heights=new int[count];
            for(int i=0;i<count;i++){var f=Analyze(idle,i,count);heights[i]=f.MaxY-f.MinY+1;}
            int referenceHeight=heights[0];
            if(!death){Array.Sort(heights);referenceHeight=heights[heights.Length/2];}
            return 52.0/referenceHeight;
        }
    }

    public static void Build(string idlePath, string sourcePath, string outputPath, int count, bool death, int frameWidth) {
        using(var source=new Bitmap(sourcePath))
        using(var atlas=new Bitmap(count*frameWidth,64,PixelFormat.Format32bppArgb)) {
            using(var graphics=Graphics.FromImage(atlas)) {
                graphics.Clear(Color.Transparent); graphics.CompositingMode=CompositingMode.SourceCopy;
                graphics.InterpolationMode=InterpolationMode.NearestNeighbor; graphics.PixelOffsetMode=PixelOffsetMode.Half;
                if(!death) {
                    int[] labels; var characters=FindCharacters(source,count,out labels); var heights=new int[count]; int maxWidth=1; for(int i=0;i<count;i++){heights[i]=characters[i].MaxY-characters[i].MinY+1;maxWidth=Math.Max(maxWidth,characters[i].MaxX-characters[i].MinX+1);} Array.Sort(heights); double scale=Math.Min(52.0/heights[count/2],(frameWidth-4.0)/maxWidth);
                    for(int i=0;i<count;i++) { var c=characters[i]; int bw=c.MaxX-c.MinX+1,bh=c.MaxY-c.MinY+1; using(var isolated=new Bitmap(bw,bh,PixelFormat.Format32bppArgb)) {
                        var columns=new int[bw]; for(int y=0;y<bh;y++)for(int x=0;x<bw;x++)if(labels[(c.MinY+y)*source.Width+c.MinX+x]==c.Id){isolated.SetPixel(x,y,source.GetPixel(c.MinX+x,c.MinY+y));columns[x]++;}
                        int window=Math.Min(bw,Math.Max(16,bh/2)),sum=0;for(int x=0;x<window;x++)sum+=columns[x];int best=sum,bestStart=0;for(int x=window;x<bw;x++){sum+=columns[x]-columns[x-window];if(sum>best){best=sum;bestStart=x-window+1;}}
                        double bodyCenter=bestStart+window/2.0; int tw=Math.Max(1,(int)Math.Round(bw*scale)),th=Math.Max(1,(int)Math.Round(bh*scale)); int localX=frameWidth/2-(int)Math.Round(bodyCenter*scale);localX=Math.Max(2,Math.Min(frameWidth-2-tw,localX));int tx=i*frameWidth+localX,ty=63-th;
                        graphics.DrawImage(isolated,new Rectangle(tx,ty,tw,th),new Rectangle(0,0,bw,bh),GraphicsUnit.Pixel);
                    }}
                } else {
                    double scale=AnimationScale(sourcePath,count,true);
                    for(int i=0;i<count;i++) { var f=Analyze(source,i,count); int slotW=f.X1-f.X0+1; double anchorX=(f.MinX+f.MaxX)/2.0; int targetW=Math.Max(1,(int)Math.Round(slotW*scale)),targetH=Math.Max(1,(int)Math.Round(source.Height*scale)); int targetX=i*frameWidth+frameWidth/2-(int)Math.Round((anchorX-f.X0)*scale),targetY=63-(int)Math.Round(f.FootY*scale); graphics.DrawImage(source,new Rectangle(targetX,targetY,targetW,targetH),new Rectangle(f.X0,0,slotW,source.Height),GraphicsUnit.Pixel); }
                }
            }
            // Runtime sprites use hard alpha so imported pixel art has no soft halo.
            for(int y=0;y<atlas.Height;y++) for(int x=0;x<atlas.Width;x++) { var c=atlas.GetPixel(x,y); atlas.SetPixel(x,y,c.A<128?Color.Transparent:Color.FromArgb(255,c.R,c.G,c.B)); }
            Directory.CreateDirectory(Path.GetDirectoryName(outputPath)); atlas.Save(outputPath,ImageFormat.Png);
        }
    }
}
'@

$sources = [ordered]@{
    idle = @('MNT-04_SCRAPPER_idle.png',6,$false,64)
    run = @('MNT-04_SCRAPPER_run.png',8,$false,64)
    attack_1 = @('MNT-04_SCRAPPER_attack_1.png',4,$false,96)
    attack_2 = @('MNT-04_SCRAPPER_attack_2.png',5,$false,96)
    hit = @('MNT-04_SCRAPPER_HIT.png',3,$false,64)
    death = @('MNT-04_SCRAPPER_death.png',6,$true,64)
}

$sourceRoot=[IO.Path]::GetFullPath($SourceDirectory); $outputRoot=[IO.Path]::GetFullPath($OutputDirectory)
$idle=Join-Path $sourceRoot 'MNT-04_SCRAPPER_idle.png'
foreach($entry in $sources.GetEnumerator()) {
    $source=Join-Path $sourceRoot $entry.Value[0]; $output=Join-Path $outputRoot ($entry.Key+'.png')
    [ScrapperConceptBuilder]::Build($idle,$source,$output,[int]$entry.Value[1],[bool]$entry.Value[2],[int]$entry.Value[3])
    Write-Output ("BUILT scrapper/{0}: {1}x64" -f $entry.Key,([int]$entry.Value[1]*[int]$entry.Value[3]))
}
