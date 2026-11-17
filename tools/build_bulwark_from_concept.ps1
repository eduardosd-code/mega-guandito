param(
    [string]$SourcePath = "$PSScriptRoot\..\assets\concept\BULWARK\CRG-12_BULWARK_source.jpg",
    [string]$OutputDirectory = "$PSScriptRoot\..\assets\enemies\sector_07\bulwark\sprites"
)

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$drawingAssembly=[Drawing.Bitmap].Assembly.Location; $runtimeDirectory=Split-Path $drawingAssembly
$references=@($drawingAssembly,(Join-Path $runtimeDirectory 'System.Drawing.Primitives.dll'),(Join-Path $runtimeDirectory 'System.Private.Windows.GdiPlus.dll'),(Join-Path $runtimeDirectory 'System.Private.Windows.Core.dll'),(Join-Path $runtimeDirectory 'System.Private.CoreLib.dll'),(Join-Path $runtimeDirectory 'System.Runtime.dll'),(Join-Path $runtimeDirectory 'System.Collections.dll'))

Add-Type -ReferencedAssemblies $references -TypeDefinition @'
using System;
using System.Collections;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;

public static class BulwarkConceptBuilder {
    class Component { public int Id,Pixels,MinX,MinY,MaxX,MaxY; public double CenterX { get { return (MinX+MaxX)/2.0; } } }
    static bool Background(Color c) {
        int max=Math.Max(c.R,Math.Max(c.G,c.B)),min=Math.Min(c.R,Math.Min(c.G,c.B));
        return max<=20 && max-min<=7;
    }

    static Bitmap TransparentCrop(Bitmap sheet, Rectangle region) {
        var bitmap=sheet.Clone(region,PixelFormat.Format32bppArgb); int w=bitmap.Width,h=bitmap.Height;
        var seen=new bool[w*h];var queue=new int[w*h];int head=0,tail=0;
        for(int x=0;x<w;x++)foreach(int y in new[]{0,h-1}){int i=y*w+x;if(!seen[i]&&Background(bitmap.GetPixel(x,y))){seen[i]=true;queue[tail++]=i;}}
        for(int y=0;y<h;y++)foreach(int x in new[]{0,w-1}){int i=y*w+x;if(!seen[i]&&Background(bitmap.GetPixel(x,y))){seen[i]=true;queue[tail++]=i;}}
        int[] dx={1,-1,0,0},dy={0,0,1,-1};
        while(head<tail){int p=queue[head++],x=p%w,y=p/w;bitmap.SetPixel(x,y,Color.Transparent);for(int d=0;d<4;d++){int nx=x+dx[d],ny=y+dy[d];if(nx<0||ny<0||nx>=w||ny>=h)continue;int np=ny*w+nx;if(!seen[np]&&Background(bitmap.GetPixel(nx,ny))){seen[np]=true;queue[tail++]=np;}}}
        // Reject residual JPEG noise while retaining dark colored armor.
        for(int y=0;y<h;y++)for(int x=0;x<w;x++){var c=bitmap.GetPixel(x,y);int max=Math.Max(c.R,Math.Max(c.G,c.B));if(c.A==0||max<10)bitmap.SetPixel(x,y,Color.Transparent);else bitmap.SetPixel(x,y,Color.FromArgb(255,c.R,c.G,c.B));}
        return bitmap;
    }

    static Rectangle Bounds(Bitmap bitmap) {
        int minX=bitmap.Width,minY=bitmap.Height,maxX=-1,maxY=-1;
        for(int y=0;y<bitmap.Height;y++)for(int x=0;x<bitmap.Width;x++)if(bitmap.GetPixel(x,y).A>0){minX=Math.Min(minX,x);maxX=Math.Max(maxX,x);minY=Math.Min(minY,y);maxY=Math.Max(maxY,y);}
        if(maxX<0)throw new InvalidDataException("Empty Bulwark frame");return Rectangle.FromLTRB(minX,minY,maxX+1,maxY+1);
    }

    static Component[] FindCharacters(Bitmap source,int expected,out int[] labels) {
        int w=source.Width,h=source.Height;labels=new int[w*h];int[] queue=new int[w*h];var components=new ArrayList();int id=0;int[] dx={-1,0,1,-1,1,-1,0,1},dy={-1,-1,-1,0,0,1,1,1};
        for(int sy=0;sy<h;sy++)for(int sx=0;sx<w;sx++){int start=sy*w+sx;if(labels[start]!=0||source.GetPixel(sx,sy).A==0)continue;id++;int head=0,tail=0;queue[tail++]=start;labels[start]=id;var c=new Component{Id=id,MinX=sx,MaxX=sx,MinY=sy,MaxY=sy};while(head<tail){int p=queue[head++],x=p%w,y=p/w;c.Pixels++;c.MinX=Math.Min(c.MinX,x);c.MaxX=Math.Max(c.MaxX,x);c.MinY=Math.Min(c.MinY,y);c.MaxY=Math.Max(c.MaxY,y);for(int d=0;d<8;d++){int nx=x+dx[d],ny=y+dy[d];if(nx<0||ny<0||nx>=w||ny>=h)continue;int np=ny*w+nx;if(labels[np]==0&&source.GetPixel(nx,ny).A>0){labels[np]=id;queue[tail++]=np;}}}if(c.Pixels>200)components.Add(c);}
        var selected=new Component[expected];var used=new bool[components.Count];for(int k=0;k<expected;k++){int best=-1;for(int i=0;i<components.Count;i++)if(!used[i]&&(best<0||((Component)components[i]).Pixels>((Component)components[best]).Pixels))best=i;if(best<0)throw new InvalidDataException("Not enough Bulwark silhouettes");used[best]=true;selected[k]=(Component)components[best];}for(int i=0;i<expected-1;i++)for(int j=i+1;j<expected;j++)if(selected[j].CenterX<selected[i].CenterX){var t=selected[i];selected[i]=selected[j];selected[j]=t;}return selected;
    }

    static double BodyCenter(Bitmap bitmap, Rectangle bounds) {
        int[] columns=new int[bounds.Width];for(int y=bounds.Top;y<bounds.Bottom;y++)for(int x=bounds.Left;x<bounds.Right;x++)if(bitmap.GetPixel(x,y).A>0)columns[x-bounds.Left]++;
        int window=Math.Min(bounds.Width,Math.Max(24,bounds.Height/2)),sum=0;for(int x=0;x<window;x++)sum+=columns[x];int best=sum,start=0;for(int x=window;x<columns.Length;x++){sum+=columns[x]-columns[x-window];if(sum>best){best=sum;start=x-window+1;}}
        return bounds.Left+start+window/2.0;
    }

    public static void Build(string sourcePath,string outputPath,int count,int sx,int sy,int sw,int sh,int frameWidth,bool death,bool connectedRow) {
        using(var sheet=new Bitmap(sourcePath)) {
            var frames=new Bitmap[count];var bounds=new Rectangle[count];var centers=new double[count];var heights=new int[count];int maxWidth=1;
            if(!death&&connectedRow){using(var row=TransparentCrop(sheet,new Rectangle(sx,sy,sw,sh))){int[] labels;var characters=FindCharacters(row,count,out labels);for(int i=0;i<count;i++){var c=characters[i];int bw=c.MaxX-c.MinX+1,bh=c.MaxY-c.MinY+1;frames[i]=new Bitmap(bw,bh,PixelFormat.Format32bppArgb);for(int y=0;y<bh;y++)for(int x=0;x<bw;x++)if(labels[(c.MinY+y)*row.Width+c.MinX+x]==c.Id)frames[i].SetPixel(x,y,row.GetPixel(c.MinX+x,c.MinY+y));bounds[i]=Bounds(frames[i]);centers[i]=BodyCenter(frames[i],bounds[i]);heights[i]=bounds[i].Height;maxWidth=Math.Max(maxWidth,bounds[i].Width);}}}
            else if(!death){int[] chargeStarts={0,145,345,535,730,875},chargeEnds={185,375,580,775,925,1080};for(int i=0;i<count;i++){int x0=sx+(count==6?chargeStarts[i]:(int)Math.Floor((double)i*sw/count)),x1=sx+(count==6?chargeEnds[i]:(int)Math.Floor((double)(i+1)*sw/count));using(var slot=TransparentCrop(sheet,new Rectangle(x0,sy,x1-x0,sh))){int[] labels;var c=FindCharacters(slot,1,out labels)[0];int bw=c.MaxX-c.MinX+1,bh=c.MaxY-c.MinY+1;frames[i]=new Bitmap(bw,bh,PixelFormat.Format32bppArgb);for(int y=0;y<bh;y++)for(int x=0;x<bw;x++)if(labels[(c.MinY+y)*slot.Width+c.MinX+x]==c.Id)frames[i].SetPixel(x,y,slot.GetPixel(c.MinX+x,c.MinY+y));bounds[i]=Bounds(frames[i]);centers[i]=BodyCenter(frames[i],bounds[i]);heights[i]=bounds[i].Height;maxWidth=Math.Max(maxWidth,bounds[i].Width);}}}
            else{for(int i=0;i<count;i++){int x0=sx+(int)Math.Floor((double)i*sw/count),x1=sx+(int)Math.Floor((double)(i+1)*sw/count);frames[i]=TransparentCrop(sheet,new Rectangle(x0,sy,x1-x0,sh));bounds[i]=Bounds(frames[i]);centers[i]=(bounds[i].Left+bounds[i].Right)/2.0;heights[i]=bounds[i].Height;maxWidth=Math.Max(maxWidth,bounds[i].Width);}}
            int referenceHeight;if(death)referenceHeight=heights[0];else{var sorted=(int[])heights.Clone();Array.Sort(sorted);referenceHeight=sorted[sorted.Length/2];}
            double scale=Math.Min(86.0/referenceHeight,(frameWidth-4.0)/maxWidth);
            using(var atlas=new Bitmap(count*frameWidth,96,PixelFormat.Format32bppArgb))using(var graphics=Graphics.FromImage(atlas)){
                graphics.Clear(Color.Transparent);graphics.CompositingMode=CompositingMode.SourceCopy;graphics.InterpolationMode=InterpolationMode.NearestNeighbor;graphics.PixelOffsetMode=PixelOffsetMode.Half;
                for(int i=0;i<count;i++){int sourceIndex=outputPath.EndsWith("attack_charge.png")?(i==2?1:(i==3?4:i)):i;var b=bounds[sourceIndex];int tw=Math.Max(1,(int)Math.Round(b.Width*scale)),th=Math.Max(1,(int)Math.Round(b.Height*scale));int localX=frameWidth/2-(int)Math.Round((centers[sourceIndex]-b.Left)*scale);localX=Math.Max(2,Math.Min(frameWidth-2-tw,localX));int tx=i*frameWidth+localX,ty=95-th;graphics.DrawImage(frames[sourceIndex],new Rectangle(tx,ty,tw,th),b,GraphicsUnit.Pixel);}
                for(int i=0;i<count;i++)frames[i].Dispose();
                graphics.Dispose();for(int y=0;y<atlas.Height;y++)for(int x=0;x<atlas.Width;x++){var c=atlas.GetPixel(x,y);atlas.SetPixel(x,y,c.A<128?Color.Transparent:Color.FromArgb(255,c.R,c.G,c.B));}Directory.CreateDirectory(Path.GetDirectoryName(outputPath));atlas.Save(outputPath,ImageFormat.Png);
            }
        }
    }
}
'@

$animations=[ordered]@{
    idle=@(6,0,0,1152,146,96,$false,$true)
    walk=@(6,0,145,1152,147,96,$false,$true)
    attack_hammer_fist=@(5,0,292,900,154,128,$false,$true)
    attack_charge=@(6,0,446,1080,120,128,$false,$false)
    attack_backhand=@(4,0,566,820,122,128,$false,$true)
    hit=@(3,0,688,384,145,96,$false,$true)
    death=@(7,384,688,896,145,128,$true,$false)
}
$source=[IO.Path]::GetFullPath($SourcePath);$outputRoot=[IO.Path]::GetFullPath($OutputDirectory)
foreach($entry in $animations.GetEnumerator()){$v=$entry.Value;$output=Join-Path $outputRoot ($entry.Key+'.png');[BulwarkConceptBuilder]::Build($source,$output,[int]$v[0],[int]$v[1],[int]$v[2],[int]$v[3],[int]$v[4],[int]$v[5],[bool]$v[6],[bool]$v[7]);Write-Output("BUILT bulwark/{0}: {1}x96" -f $entry.Key,([int]$v[0]*[int]$v[5]))}
