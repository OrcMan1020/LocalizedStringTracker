// TweetTableViewCell.m
//
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "PostTableViewCell.h"

#import "Post.h"
#import "User.h"

@import AFNetworking;

@interface PostTableViewCell ()

@property (nonatomic, strong) UILabel* nameLabel;
@property (nonatomic, strong) UIButton* moreButton;

@end

@implementation PostTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style
              reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.textColor = [UIColor darkGrayColor];
    self.detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
    self.detailTextLabel.numberOfLines = 0;
    self.selectionStyle = UITableViewCellSelectionStyleGray;
    
    
    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = self.textLabel.font;
    self.nameLabel.textColor = [UIColor orangeColor];
    self.nameLabel.text = NSLocalizedString(@"Name:", nil);
    [self.contentView addSubview:self.nameLabel];
    [self.nameLabel sizeToFit];
    
    self.moreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.moreButton setTitle:NSLocalizedString(@"More", nil) forState:UIControlStateNormal];
    [self.contentView addSubview:self.moreButton];
    [self.moreButton sizeToFit];

    return self;
}

- (void)setPost:(Post *)post {
    _post = post;

    self.textLabel.text = _post.user.username;
    self.detailTextLabel.text = _post.text;
    [self.imageView setImageWithURL:_post.user.avatarImageURL placeholderImage:[UIImage imageNamed:@"profile-image-placeholder"]];
    
    [self setNeedsLayout];
}

+ (CGFloat)heightForCellWithPost:(Post *)post {
    return (CGFloat)fmaxf(70.0f, (float)[self detailTextHeight:post.text] + 45.0f);
}

+ (CGFloat)detailTextHeight:(NSString *)text {
    CGRect rectToFit = [text boundingRectWithSize:CGSizeMake(240.0f, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0f]} context:nil];
    return rectToFit.size.height + 40.f;
}

#pragma mark - UIView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.imageView.frame = CGRectMake(10.0f, 10.0f, 50.0f, 50.0f);
    self.nameLabel.frame = CGRectMake(70.0f, 6.0f, self.nameLabel.frame.size.width, 20.0f);
    self.textLabel.frame = CGRectMake(CGRectGetMaxX(self.nameLabel.frame)+6.f, 6.0f, 240.0f, 20.0f);
    
    CGRect detailTextLabelFrame = CGRectMake(70.0f, 25.f, 240.0f, 0);
    CGFloat calculatedHeight = [[self class] detailTextHeight:self.post.text];
    detailTextLabelFrame.size.height = calculatedHeight;
    self.detailTextLabel.frame = detailTextLabelFrame;
    
    self.moreButton.frame = CGRectMake(self.contentView.frame.size.width-self.moreButton.frame.size.width-10.f, CGRectGetMaxY(self.detailTextLabel.frame)-10.f, self.moreButton.frame.size.width, 20.0f);
}

@end
