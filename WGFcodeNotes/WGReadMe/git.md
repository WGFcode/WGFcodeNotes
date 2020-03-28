# Git学习心得
## 一.配置
1. 在本地创建一个新的工程项目，项目名称:WGGitLearnProject，打开命令行，cd到该目录下 
2. git init                                                                              :初始化一个空的git仓库
3. git config --global user.name "baiaicaiai"                       :配置github的用户名称
4. git config --global user.emial "1813061716@qq.com"   :配置github的用户邮箱
5. git add .                                                                           :将本地项目添加到git的暂存区  
6. git commit -m "功能描述"                   :初始化本地项目并添加到git本地仓库" 
7. git remote add origin https://github.com/WGFcode/WGFcodeNotes.git   :初次添加到GitHub上需要和Github上的项目地址绑定
8. git push -u origin master                       :将项目推送的远程仓库
9. 如果是从仓库中拷贝代码到本地，在本地创建空的文件，然后使用git clone https://github.com/WGFcode/WGFcodeNotes.git 将远程仓库代码拷贝到本地创建的空文件中

#3. 命令行释意
#工作区

    1.git status            :查看当前工作区的状态，告诉你哪些文件被修改过
    2.git diff              :查看工程中被修改的内容
      git diff 文件1路径     :查看文件1被修改的内容
    3.git checkout .        :丢弃工作区文的所有文件修改
      git checkout -- 文件1路径  :若在工作区，即没有执行git add . 前，对本地工作区进行了修改，但想回退到没有修改前， 
      
#暂存区

    1.git add .          :将工作区的修改添加到暂存区
      git add 文件1路径    :将工作区的某一个文件的修改添加到咱存区
    2.git diff --cached   :查看暂存区和工作区的区别
      git diff --cached 文件1路径 :查看文件1的暂存区与工作区的区别
    3.git reset head 文件1路径 :将添加到暂存区的文件1回退到工作区，注意文件1中的修改代码在工作区还存在，只是文件1不在暂存区了，如果想丢弃工作区文件1的修改，继续使用git checkout -- 文件1路径即可
     git reset head  :将添加到暂存区的全部文件回退到工作区，代码依然存在，只是不再添加到暂存区了
#本地仓库

     1.即git add . 又git commit -m ""  此时代码已经添加到了本地仓库，但是并没有添加到远程仓库
     2.使用git log 查看历史版本，或者使用git reflog查看历史版本
             localhost:WGGitLearnProject wubaicai$ git log
             commit f190044a70110480d940d012ddd70f8c03854e2a (HEAD -> master)
             Author: baiaicaiai <1813061716@qq.com>
             Date:   Sun Aug 26 18:26:21 2018 +0800
             
             add UIButton
             
             commit 96954374b3e342c0c00e92648ed197015a5178d7
             Author: baiaicaiai <1813061716@qq.com>
             Date:   Sun Aug 26 18:22:13 2018 +0800
             
             add ViewController View is Red Color
             
             commit cbb928c10765f26f9108057bb27d4f70e6b95329 (origin/master)
             Author: baiaicaiai <1813061716@qq.com>
             Date:   Sun Aug 26 17:11:16 2018 +0800
             
             Location new project push to github
       git reset --hard 96954374b3e342c0c00e92648ed197015a5178d7将add UIButton版本回退到add ViewController View is Red Color的版本，此时工作区的代码都显示成了add ViewController View is Red Color版本时候的代码。如果想重新回到 add UIButton的版本，使用git reflog 
               localhost:WGGitLearnProject wubaicai$ git reflog
               9695437 (HEAD -> master) HEAD@{0}: reset: moving to 96954374b3e342c0c00e92648ed197015a5178d7
               f190044 HEAD@{1}: reset: moving to f190044a70110480d940d012ddd70f8c03854e2a
               f190044 HEAD@{2}: commit: add UIButton
               9695437 (HEAD -> master) HEAD@{3}: commit: add ViewController View is Red Color
               cbb928c (origin/master) HEAD@{4}: commit (initial): Location new project push to github
               localhost:WGGitLearnProject wubaicai$ git reset --hard f190044


#添加忽略项目部分文件改变的配置文件

    1.在工程目录中，touch .gitignore 创建配置文件(若不现实，使用ls -ah 显示隐藏文件)
    2.open .gitignore 打开配置文件，将https://github.com/github/gitignore/blob/master/Swift.gitignore中的内容复制粘贴
    3.添加到仓库中
    4.如果.gitignore规则不生效:先把本地缓存删除然后更新
    git rm -r --cached .


#其它命令行分析

    1.git branch             :查看当前工程下的分支，当前分支前用*标记
    2.git branch XX          :创建XX的分支名称
    3.git checkout XX        :切换到XX分支上
    4.git checkout -b XX     :创建并切换到XX分支上，相当于12命令行
    5.创建分支testBranch完成功能后，先切换到主分支上
        git checkout -b testBranch   :创建并切换到分支testBranch上，完成部分功能开发后
        git add .    git commit -m "完成分支上功能的开发了"
        git checkout master   :切到主分支上
        git merge testBranch   :将testBranch分支合并到当前分支(master分支)
    6.完成分支合并后，就可以删除分支了
        git branch -d testBranch
    7.注意:在分支1上添加功能,当切换到另一个分支2(例如master分支),分支1上的代码是不会在分支2上显示的
#多任务多分支协作
        
    当当前项目并没有完成，但需要去做开发新的需求的时候。或者当前master指定的是线上的版本，需要做新的需求的时候，但在做新需求的过程中，可能线上会出现BUG需要修复的时候，这种情况需要进行分支管理
    1.git branch 分支名称1branch1        :创建分支branch1
    2.git checkout 分支名称1             :切换到分支branch1
    3.在branch1分支上进行开发，但可能分支任务需要好几天完成，但每天都要提交代码到远程仓库
    4.git add .   
    5.git commit -m "描述"
    6.git push --set-upstream origin branch1  将branch1的代码提交到远程仓库

#同步远程仓库分支
    
    1.本地有新分支，远程仓库没有
        git add . 
        add commit -m "添加新分支"
        git push --set-upstream origin 新分支名称
    2.远程仓库有新分支，本地没有
        git branch 和git branch -a 查看本地分支和远程分支
        若没有发现远程分支，则使用
        git fetch  远程主机的更新全部取回本地
        git checkout -b 本地分支名 origin/远程分支名  //在本地创建本地分支(和远程分支名相同)，拉取远程分支到本地，并切换到该分支
        git pull origin 远程分支名  //拉取远程分支到本地
    3.本地删除了分支，远程也想删除。
        git branch -d 分支名        //删除本地分支
        git push origin -d 分支名   //删除远程分支
    4.远程删除了分支，本地也想删除
        git branch 查看本地分支 
        git branch -a 查看远程分支
        git remote show origin    //查看远程分支和本地分支的对应关系
        git remote prune origin   //删除远程已经删除过的分支



#⚠️如果拷贝本地项目A到项目B，项目B再重新提交到新的仓库,一定要先将B代码中的git管理删除(命令行: find ./ -name .git -exec rm -rf {} \;),然后重新提交到新的仓库

    1.git init 
    2.git remote add origin http://xxx/xxx.git
    3.git add .
    4.git commit -m "例如：创建新的项目"
    5.git push -u origin master
