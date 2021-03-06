//
//  UIScrollView+CustomRefresh.m
//  CustomRefresh
//
//  Created by oucaizi on 15/11/24.
//  Copyright © 2015年 oucaizi. All rights reserved.
//

#import "UIScrollView+ShowHeadImage.h"
#import <objc/runtime.h>

@interface CustomRefreshView ()

/**
 *  kvo监听当前视图是否处于监听状态
 */
@property(nonatomic,assign) BOOL isObserving;

@property(nonatomic) UIImage *picImage;

@end


static CGFloat const RefreshViewHeight = 260;
static const char *refreshViewKey ;

@implementation UIScrollView (ShowHeadImage)

@dynamic showHeadImage,refreshView;

-(void)addHeaderImage:(UIImage*)image{
    
    if (!self.refreshView) {
        [self setContentInset:UIEdgeInsetsMake(RefreshViewHeight, 0, 0, 0)];
        CustomRefreshView *view=[[CustomRefreshView alloc] initWithFrame:CGRectMake(0, -RefreshViewHeight, CGRectGetWidth(self.bounds), RefreshViewHeight)];
        view.picImage=image;
        self.refreshView=view;
        [self addSubview:self.refreshView];
        self.showHeadImage = YES;
    }
}


#pragma mark setter/getter

//类别中增加方法用runtime重新合成属性
-(void)setRefreshView:(CustomRefreshView *)refreshView{
     objc_setAssociatedObject(self, &refreshViewKey, refreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(CustomRefreshView*)refreshView{
  return   objc_getAssociatedObject(self, &refreshViewKey);
}

-(void)setShowHeadImage:(BOOL)showHeadImage{
    if (showHeadImage) {
        //self.refreshView 作为kvo观察者
        if (!self.refreshView.isObserving) {
            [self addObserver:self.refreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            self.refreshView.isObserving=YES;
        }
    }else{
        
        if (!self.refreshView.isObserving) {
            [self removeObserver:self.refreshView forKeyPath:@"contentOffset"];
            self.refreshView.isObserving=NO;
        }
    }
}


-(void)dealloc
{
    [self removeObserver:self.refreshView forKeyPath:@"contentOffset"];
}

@end


@implementation CustomRefreshView


@synthesize hImageView=_hImageView;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self.hImageView setFrame:self.bounds];
        [self addSubview:self.hImageView];
    }
    return self;
}

-(void)setPicImage:(UIImage *)picImage{
    _picImage=picImage;
    [self.hImageView setImage:_picImage];
}

-(void)willMoveToSuperview:(UIView *)newSuperview{
    if (self.superview&&newSuperview==nil) {
        UIScrollView *scrollView=(UIScrollView *)self.superview;
        if (scrollView.showHeadImage) {
            if (self.isObserving) {
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
            }
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark scrollViewDelegate

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    CGFloat y=contentOffset.y;
    if (y<-RefreshViewHeight) {
        CGRect frame = self.frame;
        frame.origin.y = y;
        frame.size.height =  -y;
        self.frame = frame;
        [self.hImageView setFrame:self.bounds];
    }
}

#pragma mark setter

-(UIImageView*)hImageView{
    if (!_hImageView) {
        _hImageView =[[UIImageView alloc] init];
        [_hImageView setContentMode:UIViewContentModeScaleAspectFill];
    }
    return _hImageView;
}

@end