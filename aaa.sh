 @Override
    public BidStatusVo queryStatus(BidQueryStatus queryStatus) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(queryStatus.getBjbh(), queryStatus.getBdh(), queryStatus.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }
        List<SectionStatusVo> sectionStatusVos = evaluationResultService.selectSectionStatusVoListByProjectId(projectId);
        BidStatusVo bidStatusVo = new BidStatusVo();
        BeanUtils.copyProperties(queryStatus, bidStatusVo);
        bidStatusVo.setSectionStatusList(sectionStatusVos);
        return bidStatusVo;
    }

    @Override
    public BidScoreVo queryByTkbm(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }
        EvaluationClause queryTkbm = new EvaluationClause();
        queryTkbm.setClauseCode(scoreQuery.getTkbm());
        EvaluationClause evaluationClause = evaluationClauseService.selectEvaluationClauseList(queryTkbm).stream().findFirst().orElse(null);
        EvaluationResult params = new EvaluationResult();
        params.setProjectId(projectId);
        params.setClauseId(evaluationClause.getId());
        EvaluationResult evaluationResult = evaluationResultService.selectEvaluationResultList(params).stream().findFirst().orElse(null);
        return null;
    }

    public JGBAjaxResult queryStatus(@RequestBody BidQueryStatus queryStatus) {
        JGBAjaxResult valid = validateBaseParams(queryStatus.getBdh(), queryStatus.getBjbh(), queryStatus.getZbid());
        if (valid != null) {
            return valid;
        }

        BidStatusVo vo = bidExternalInterfaceService.queryStatus(queryStatus);
        return successOrFail(vo);
    }

    @Override
    public BidScoreDetailVo query(BidScoreQuery scoreQuery) {
        Long projectId = projectService.findProjectIdByBdhBjbhZbid(scoreQuery.getBjbh(), scoreQuery.getBdh(), scoreQuery.getZbid());
        if (projectId == null || projectId <= 0) {
            throw new RuntimeException("项目不存在");
        }
        List<ScoreDetail> scoreDetails = evaluationResultService.selectScoreDetailListByProjectId(projectId);
        BidScoreDetailVo detailVo = new BidScoreDetailVo();
        BeanUtils.copyProperties(scoreQuery, detailVo);
        detailVo.setScoreDetails(scoreDetails);
        detailVo.setTimestamp(DateUtils.getNowDate().getTime());
        return detailVo;
    }